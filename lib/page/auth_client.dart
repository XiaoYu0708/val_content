// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

String? authToken;
String? idToken;
String? shard;
String? entitlementToken;
Map<String, dynamic>? accountXP;
Map<String, dynamic>? playerInfo;
Map<String, dynamic>? wallet;
Map<String, dynamic>? storefront;
// 新增：玩家目前牌位 (integer)
int playerRankInt = -1;
// 新增：玩家目前牌位分數 (Ranked Rating)
int playerRankRR = -1;
// 新增：避免重複請求
bool _isFetchingMMR = false;

class RiotLoginPage extends StatefulWidget {
  const RiotLoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RiotLoginPageState createState() => _RiotLoginPageState();
}

class _RiotLoginPageState extends State<RiotLoginPage> {
  late final WebViewController _controller;

  final String loginUrl =
      'https://auth.riotgames.com/authorize?redirect_uri=https%3A%2F%2Fplayvalorant.com%2Fopt_in&client_id=play-valorant-web-prod&response_type=token%20id_token&nonce=1&scope=account%20openid';

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('access_token=') &&
                request.url.contains('id_token=')) {
              final extractedAuthToken =
                  _extractTokenFromUrl(request.url, 'access_token');
              final extractedIdToken =
                  _extractTokenFromUrl(request.url, 'id_token');
              if (extractedAuthToken != null && extractedIdToken != null) {
                if (mounted) {
                  setState(() {
                    authToken = extractedAuthToken;
                    idToken = extractedIdToken;
                    isLoggedIn = true;
                  });
                  _fetchPlayerInfo(authToken!);
                  _fetchRiotGeo(authToken!, idToken!);
                  _fetchEntitlementsToken(authToken!);
                }
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  Future<void> _fetchPlayerInfo(String token) async {
    final url = Uri.parse('https://auth.riotgames.com/userinfo');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          playerInfo = data;
        });
      }
      _tryFetchAccountXPIfReady();
      _tryFetchWalletIfReady();
      _tryFetchStorefrontIfReady(); // 新增
    } else {
      debugPrint('取得玩家資訊失敗：狀態碼 ${response.statusCode}');
    }
  }

  Future<void> _fetchRiotGeo(String authToken, String idToken) async {
    final url = Uri.parse(
        'https://riot-geo.pas.si.riotgames.com/pas/v1/product/valorant');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          shard = data['affinities']?['live'];
        });
      }
      _tryFetchAccountXPIfReady();
      _tryFetchWalletIfReady();
      _tryFetchStorefrontIfReady(); // 新增
    } else {
      debugPrint('取得 Riot Geo 失敗，狀態碼：${response.statusCode}');
    }
  }

  Future<void> _fetchEntitlementsToken(String authToken) async {
    final url =
        Uri.parse('https://entitlements.auth.riotgames.com/api/token/v1');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          entitlementToken = data['entitlements_token'];
        });
      }
      _tryFetchAccountXPIfReady();
      _tryFetchWalletIfReady();
      _tryFetchStorefrontIfReady();
    } else {
      debugPrint('取得 Entitlements Token 失敗：狀態碼 ${response.statusCode}');
    }
  }

  void _tryFetchAccountXPIfReady() {
    if (shard != null &&
        playerInfo != null &&
        entitlementToken != null &&
        authToken != null) {
      _fetchAccountXP();
      // 新增：嘗試抓取牌位
      _tryFetchPlayerMMRIfReady();
    }
  }

  void _tryFetchWalletIfReady() {
    if (shard != null &&
        playerInfo != null &&
        entitlementToken != null &&
        authToken != null) {
      _fetchWallet();
      // 新增：嘗試抓取牌位
      _tryFetchPlayerMMRIfReady();
    }
  }

  void _tryFetchStorefrontIfReady() {
    if (shard != null &&
        playerInfo != null &&
        entitlementToken != null &&
        authToken != null) {
      _fetchStorefront();
      // 新增：嘗試抓取牌位
      _tryFetchPlayerMMRIfReady();
    }
  }

  // 新增：條件判斷後抓取玩家牌位
  void _tryFetchPlayerMMRIfReady() {
    if (_isFetchingMMR) return;
    if (playerRankInt != -1) return;
    if (shard != null &&
        playerInfo != null &&
        entitlementToken != null &&
        authToken != null) {
      _fetchPlayerRank();
    }
  }

  // 新增：抓取玩家牌位
  Future<void> _fetchPlayerRank() async {
    if (playerInfo == null ||
        shard == null ||
        entitlementToken == null ||
        authToken == null) {
      return;
    }

    _isFetchingMMR = true;
    final puuid = playerInfo!['sub'];
    final url = Uri.parse('https://pd.$shard.a.pvp.net/mmr/v1/players/$puuid');

    const clientPlatformJson = '''
{
  "platformType": "PC",
  "platformOS": "Windows",
  "platformOSVersion": "10.0.19042.1.256.64bit",
  "platformChipset": "Unknown"
}
''';
    final clientPlatform = base64Encode(utf8.encode(clientPlatformJson));
    const clientVersion = 'release-11.07-shipping-7-3836447';

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'X-Riot-Entitlements-JWT': entitlementToken!,
          'X-Riot-ClientPlatform': clientPlatform,
          'X-Riot-ClientVersion': clientVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 優先：QueueSkills.competitive
        final queueSkills = data['QueueSkills'];
        if (queueSkills != null && queueSkills['competitive'] != null) {
          final comp = queueSkills['competitive'];
          final tierNum = comp['CompetitiveTier'];
          if (tierNum is int && tierNum > 0) {
            playerRankInt = tierNum;
          }
          final rankedRating = comp['RankedRating'];
          if (rankedRating is int) {
            playerRankRR = rankedRating;
          }
        }

        // 補：LatestCompetitiveUpdate
        if (playerRankInt == -1 &&
            data['LatestCompetitiveUpdate'] != null &&
            data['LatestCompetitiveUpdate']['TierAfterUpdate'] is int) {
          playerRankInt = data['LatestCompetitiveUpdate']['TierAfterUpdate'];
        }
        if (playerRankRR == -1 &&
            data['LatestCompetitiveUpdate'] != null &&
            data['LatestCompetitiveUpdate']['RankedRatingAfterUpdate'] is int) {
          playerRankRR =
              data['LatestCompetitiveUpdate']['RankedRatingAfterUpdate'];
        }

        // 再補：SeasonalInfoBySeasonID (找第一個有 RankedRating 的)
        if ((playerRankRR == -1 || playerRankInt == -1) &&
            data['SeasonalInfoBySeasonID'] is Map) {
          final seasonal = data['SeasonalInfoBySeasonID'] as Map;
          for (final entry in seasonal.values) {
            if (entry is Map) {
              if (playerRankInt == -1 &&
                  entry['CompetitiveTier'] is int &&
                  (entry['CompetitiveTier'] as int) > 0) {
                playerRankInt = entry['CompetitiveTier'];
              }
              if (playerRankRR == -1 && entry['RankedRating'] is int) {
                playerRankRR = entry['RankedRating'];
              }
            }
          }
        }

        if (mounted) {
          setState(() {});
        }
      } else {
        debugPrint('取得 MMR 失敗：${response.statusCode}');
      }
    } catch (e) {
      debugPrint('取得 MMR 發生錯誤：$e');
    } finally {
      _isFetchingMMR = false;
    }
  }

  // 新增：數字段位對應文字 (簡化版，可能與賽季調整略有差異)
  String _mapTierNumberToRank(int tier) {
    const map = {
      0: 'Unrated',
      3: 'Iron 1',
      4: 'Iron 2',
      5: 'Iron 3',
      6: 'Bronze 1',
      7: 'Bronze 2',
      8: 'Bronze 3',
      9: 'Silver 1',
      10: 'Silver 2',
      11: 'Silver 3',
      12: 'Gold 1',
      13: 'Gold 2',
      14: 'Gold 3',
      15: 'Platinum 1',
      16: 'Platinum 2',
      17: 'Platinum 3',
      18: 'Diamond 1',
      19: 'Diamond 2',
      20: 'Diamond 3',
      21: 'Ascendant 1',
      22: 'Ascendant 2',
      23: 'Ascendant 3',
      24: 'Immortal 1',
      25: 'Immortal 2',
      26: 'Immortal 3',
      27: 'Radiant',
    };
    return map[tier] ?? 'Unrated';
  }

  Future<void> _fetchAccountXP() async {
    if (playerInfo == null ||
        shard == null ||
        entitlementToken == null ||
        authToken == null) {
      debugPrint('缺少必要參數，無法取得 Account XP');
      return;
    }
    final puuid = playerInfo!['sub'];
    final url =
        Uri.parse('https://pd.$shard.a.pvp.net/account-xp/v1/players/$puuid');

    const clientPlatformJson = '''
{
  "platformType": "PC",
  "platformOS": "Windows",
  "platformOSVersion": "10.0.19042.1.256.64bit",
  "platformChipset": "Unknown"
}
''';
    final clientPlatform = base64Encode(utf8.encode(clientPlatformJson));
    const clientVersion = 'release-01.00-shipping-12-07-2023';

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'X-Riot-Entitlements-JWT': entitlementToken!,
        'X-Riot-ClientPlatform': clientPlatform,
        'X-Riot-ClientVersion': clientVersion,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          accountXP = data;
        });
      }
    } else {
      debugPrint('取得 Account XP 失敗：狀態碼 ${response.statusCode}');
    }
  }

  Future<void> _fetchWallet() async {
    if (playerInfo == null ||
        shard == null ||
        entitlementToken == null ||
        authToken == null) {
      debugPrint('缺少必要參數，無法取得 Wallet');
      return;
    }
    final puuid = playerInfo!['sub'];
    final url = Uri.parse('https://pd.$shard.a.pvp.net/store/v1/wallet/$puuid');

    const clientPlatformJson = '''
{
  "platformType": "PC",
  "platformOS": "Windows",
  "platformOSVersion": "10.0.19042.1.256.64bit",
  "platformChipset": "Unknown"
}
''';
    final clientPlatform = base64Encode(utf8.encode(clientPlatformJson));
    const clientVersion = 'release-01.00-shipping-12-07-2023';

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'X-Riot-Entitlements-JWT': entitlementToken!,
        'X-Riot-ClientPlatform': clientPlatform,
        'X-Riot-ClientVersion': clientVersion,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          wallet = data;
        });
      }
    } else {
      debugPrint('取得 Wallet 失敗：狀態碼 ${response.statusCode}');
    }
  }

  // 新增商店資料獲取方法
  Future<void> _fetchStorefront() async {
    if (playerInfo == null ||
        shard == null ||
        entitlementToken == null ||
        authToken == null) {
      debugPrint('缺少必要參數，無法取得 Storefront');
      return;
    }
    final puuid = playerInfo!['sub'];
    final url =
        Uri.parse('https://pd.$shard.a.pvp.net/store/v3/storefront/$puuid');

    const clientPlatformJson = '''
{
  "platformType": "PC",
  "platformOS": "Windows",
  "platformOSVersion": "10.0.19042.1.256.64bit",
  "platformChipset": "Unknown"
}
''';
    final clientPlatform = base64Encode(utf8.encode(clientPlatformJson));
    const clientVersion = 'release-01.00-shipping-12-07-2023';

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'X-Riot-Entitlements-JWT': entitlementToken!,
        'X-Riot-ClientPlatform': clientPlatform,
        'X-Riot-ClientVersion': clientVersion,
        'Content-Type': 'application/json',
      },
      body: '{}', // 空 JSON 主體，上傳表示請求有效
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          storefront = data;
        });
      }
    } else {
      debugPrint('取得 Storefront 失敗：狀態碼 ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F1419) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4654),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('VALORANT',
                style: TextStyle(
                    color: null, // 使用主題預設顏色
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        backgroundColor: isDarkMode ? const Color(0xFF0F1419) : Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        actions: [
          if (isLoggedIn)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: FlutterI18n.translate(
                context,
                "Page.AuthClient.Logout.title",
              ),
              color: isDarkMode ? Colors.white : Colors.black,
            ),
        ],
      ),
      body: isLoggedIn
          ? playerInfo != null
              ? _buildPlayerInfo()
              : _buildLoadingView()
          : WebViewWidget(controller: _controller),
    );
  }

  Widget _buildLoadingView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0F1419), const Color(0xFF1E2328)]
              : [Colors.grey[50]!, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4654)),
            ),
            const SizedBox(height: 20),
            Text(
              FlutterI18n.translate(
                context,
                "Page.AuthClient.Loading",
              ),
              style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0F1419), const Color(0xFF1E2328)]
              : [Colors.grey[50]!, Colors.grey[100]!],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildPlayerCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            if (wallet != null) _buildWalletCard(),
            const SizedBox(height: 20),
            if (storefront != null) ...[
              _buildDailyStoreCard(),
              const SizedBox(height: 20),
              _buildBonusStoreCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2328), const Color(0xFF2A2D31)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4654),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4654).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${playerInfo!['acct']['game_name']}#${playerInfo!['acct']['tag_line']}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: shard == 'ap' ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${shard?.toUpperCase() ?? FlutterI18n.translate(
                                  context,
                                  "Page.AuthClient.Loading",
                                )} ${FlutterI18n.translate(
                              context,
                              "Page.AuthClient.Server",
                            )}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (playerRankInt != -1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4654), Color(0xFFE53945)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 新增：牌位小圖示
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.network(
                                    'https://media.valorant-api.com/competitivetiers/564d8e28-c226-3180-6285-e48a390db8b1/$playerRankInt/smallicon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.military_tech,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  playerRankRR != -1
                                      ? '${_mapTierNumberToRank(playerRankInt)} ($playerRankRR RR)'
                                      : _mapTierNumberToRank(playerRankInt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (accountXP != null) _buildLevelProgress(),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final level = accountXP!['Progress']['Level'] ?? 0;
    final currentXP = accountXP!['Progress']['XP'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF16181D) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Lavel",
                )} $level',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentXP XP',
                style: const TextStyle(
                  color: Color(0xFFFF4654),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (currentXP % 1000) / 1000,
            backgroundColor:
                isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4654)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.public,
          title: FlutterI18n.translate(
            context,
            "Page.AuthClient.Contry",
          ),
          value: playerInfo!['country'] ?? '未知',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.email,
          title: FlutterI18n.translate(
            context,
            "Page.AuthClient.Email",
          ),
          value: playerInfo!['email_verified']
              ? FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Verified",
                )
              : FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Unverified",
                ),
          color: playerInfo!['email_verified'] ? Colors.green : Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.phone,
          title: FlutterI18n.translate(
            context,
            "Page.AuthClient.Phone",
          ),
          value: playerInfo!['phone_number_verified']
              ? FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Verified",
                )
              : FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Unverified",
                ),
          color: playerInfo!['phone_number_verified']
              ? Colors.green
              : Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.verified_user,
          title: FlutterI18n.translate(
            context,
            "Page.AuthClient.AccountInfo",
          ),
          value: playerInfo!['account_verified']
              ? FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Verified",
                )
              : FlutterI18n.translate(
                  context,
                  "Page.AuthClient.Unverified",
                ),
          color: playerInfo!['account_verified'] ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2328), const Color(0xFF2A2D31)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final balances = wallet?['Balances'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2328), const Color(0xFF2A2D31)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                FlutterI18n.translate(
                  context,
                  "Page.AuthClient.WalletBalance",
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...balances.entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? const Color(0xFF16181D) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [
                                  const Color(0xFF3C3C41),
                                  const Color(0xFF2A2D31)
                                ]
                              : [
                                  const Color(0xFF2C2C2E),
                                  const Color(0xFF1C1C1E)
                                ], // 淺色模式使用深色漸層
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF4A4A4F)
                                : const Color(0xFF3A3A3C),
                            width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: isDarkMode
                              ? const Color(0xFF2A2D31)
                              : const Color(0xFF1C1C1E), // 淺色模式使用深色背景
                          child: Image.network(
                            'https://media.valorant-api.com/currencies/${e.key}/largeicon.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCurrencyName(e.key),
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.value}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 新增商店卡片 Widget
  Widget _buildDailyStoreCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final skinsPanelLayout =
        storefront?['SkinsPanelLayout'] as Map<String, dynamic>? ?? {};
    final singleItemStoreOffers =
        skinsPanelLayout['SingleItemStoreOffers'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2328), const Color(0xFF2A2D31)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                FlutterI18n.translate(
                  context,
                  "Page.AuthClient.dailyStore",
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4654),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDailyStoreTimeRemaining(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: singleItemStoreOffers.length,
            itemBuilder: (context, index) {
              final offer =
                  singleItemStoreOffers[index] as Map<String, dynamic>;
              return _buildSkinOfferCard(offer, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  // 夜市卡片
  Widget _buildBonusStoreCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bonusStore = storefront?['BonusStore'] as Map<String, dynamic>? ?? {};
    final bonusOffers = bonusStore['BonusStoreOffers'] as List<dynamic>? ?? [];

    if (bonusOffers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF1E2328), const Color(0xFF2A2D31)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                FlutterI18n.translate(
                  context,
                  "Page.AuthClient.NightMarket",
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4654),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getBonusStoreTimeRemaining(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: bonusOffers.length > 6 ? 6 : bonusOffers.length,
              itemBuilder: (context, index) {
                final offer = bonusOffers[index] as Map<String, dynamic>;
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildBonusOfferCard(offer, isDarkMode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinOfferCard(Map<String, dynamic> offer, bool isDarkMode) {
    final offerId = offer['OfferID'] as String? ?? '';
    final cost = offer['Cost'] as Map<String, dynamic>? ?? {};
    final costEntries = cost.entries.toList();

    return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF16181D) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2D31) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    'https://media.valorant-api.com/weaponskinlevels/$offerId/displayicon.png',
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDarkMode
                          ? const Color(0xFF3C3C41)
                          : Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDarkMode ? Colors.white54 : Colors.grey[400],
                        size: 32,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF4654)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (costEntries.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF16181D)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                'https://media.valorant-api.com/currencies/85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741/largeicon.png',
                                color: isDarkMode
                                    ? Colors.grey[100]
                                    : const Color(0xFF16181D),
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.monetization_on,
                                        color: Colors.amber, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${costEntries.first.value}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildBonusOfferCard(
      Map<String, dynamic> bonusOffer, bool isDarkMode) {
    final offer = bonusOffer['Offer'] as Map<String, dynamic>;
    final discountPercent = bonusOffer['DiscountPercent'] ?? 0;
    final discountCosts =
        bonusOffer['DiscountCosts'] as Map<String, dynamic>? ?? {};
    final originalCost =
        offer['Cost']['85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741'] ?? 0;
    final discountedCost =
        discountCosts['85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741'] ?? originalCost;
    final offerId = offer['OfferID'] as String? ?? '';

    return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF16181D) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF3C3C41) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (discountPercent > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Image.network(
                        'https://media.valorant-api.com/weaponskinlevels/$offerId/displayicon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: isDarkMode ? Colors.white54 : Colors.grey[400],
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (discountPercent > 0)
                      Text(
                        '$originalCost',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF16181D)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.network(
                                'https://media.valorant-api.com/currencies/85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741/largeicon.png',
                                color: isDarkMode
                                    ? Colors.grey[100]
                                    : const Color(0xFF16181D),
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.monetization_on,
                                        color: Colors.amber, size: 12)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$discountedCost',
                          style: TextStyle(
                            color: discountPercent > 0
                                ? const Color(0xFF4CAF50)
                                : (isDarkMode ? Colors.white : Colors.black87),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  String _getDailyStoreTimeRemaining() {
    if (storefront == null) {
      return FlutterI18n.translate(
        context,
        "Page.AuthClient.Loading",
      );
    }

    final skinsPanelLayout =
        storefront!['SkinsPanelLayout'] as Map<String, dynamic>? ?? {};
    final remainingSeconds =
        skinsPanelLayout['SingleItemOffersRemainingDurationInSeconds']
                as int? ??
            0;

    final duration = Duration(seconds: remainingSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '$hours ${FlutterI18n.translate(
      context,
      "Page.AuthClient.hour",
    )} $minutes ${FlutterI18n.translate(
      context,
      "Page.AuthClient.minute",
    )}';
  }

  String _getBonusStoreTimeRemaining() {
    if (storefront == null) {
      return FlutterI18n.translate(
        context,
        "Page.AuthClient.Loading",
      );
    }

    final bonusStore = storefront!['BonusStore'] as Map<String, dynamic>? ?? {};
    final remainingSeconds =
        bonusStore['BonusStoreRemainingDurationInSeconds'] as int? ?? 0;

    final duration = Duration(seconds: remainingSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    if (days > 0) {
      return '$days ${FlutterI18n.translate(
        context,
        "Page.AuthClient.day",
      )} $hours ${FlutterI18n.translate(
        context,
        "Page.AuthClient.hour",
      )}';
    } else {
      return '$hours ${FlutterI18n.translate(
        context,
        "Page.AuthClient.hour",
      )} ${duration.inMinutes % 60} ${FlutterI18n.translate(
        context,
        "Page.AuthClient.minute",
      )}';
    }
  }

  Future<void> _logout() async {
    try {
      // 顯示確認對話框
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E2328) : Colors.white,
            title: Text(
              FlutterI18n.translate(
                context,
                "Page.AuthClient.Logout.confirmTitle",
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              FlutterI18n.translate(
                context,
                "Page.AuthClient.Logout.content",
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    "Page.AuthClient.Logout.cancel",
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4654),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    "Page.AuthClient.Logout.confirm",
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true) {
        // 顯示載入指示器
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    FlutterI18n.translate(
                      context,
                      "Page.AuthClient.Logout.loggingOut",
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2196F3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }

        try {
          // 先導向 Riot 登出頁面
          await _controller
              .loadRequest(Uri.parse('https://auth.riotgames.com/logout'));

          // 等待登出完成
          await Future.delayed(const Duration(seconds: 3));

          // 清除 WebView 的 cookies 和緩存
          await _controller.clearCache();
          await _controller.clearLocalStorage();

          // 清除本地狀態
          if (mounted) {
            setState(() {
              isLoggedIn = false;
              authToken = null;
              idToken = null;
              shard = null;
              entitlementToken = null;
              accountXP = null;
              playerInfo = null;
              wallet = null;
              storefront = null;
              playerRankInt = -1; // 新增重置
              playerRankRR = -1; // 新增重置
            });
          }

          // 重新導向到登入頁面
          if (mounted) {
            await _controller.loadRequest(Uri.parse(loginUrl));
          }

          // 清除之前的 SnackBar 並顯示成功訊息
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  FlutterI18n.translate(
                    context,
                    "Page.AuthClient.Logout.loggedOut",
                  ),
                ),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } catch (logoutError) {
          debugPrint('登出過程中發生錯誤：$logoutError');

          // 即使有錯誤也清除本地狀態
          if (mounted) {
            setState(() {
              isLoggedIn = false;
              authToken = null;
              idToken = null;
              shard = null;
              entitlementToken = null;
              accountXP = null;
              playerInfo = null;
              wallet = null;
            });
          }

          // 重新導向到登入頁面
          if (mounted) {
            await _controller.loadRequest(Uri.parse(loginUrl));
          }

          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  FlutterI18n.translate(
                    context,
                    "Page.AuthClient.Logout.LogoutButError",
                  ),
                ),
                backgroundColor: const Color(0xFFFF9800),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('登出時發生錯誤：$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(
                context,
                "Page.AuthClient.Logout.error",
              ),
            ),
            backgroundColor: const Color(0xFFFF4654),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  String _getCurrencyName(String currencyId) {
    switch (currencyId) {
      case '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741':
        return FlutterI18n.translate(
          context,
          "Page.AuthClient.currencies.ValorantPoints",
        );
      case '85ca954a-41f2-ce94-9b45-8ca3dd39a00d':
        return FlutterI18n.translate(
          context,
          "Page.AuthClient.currencies.KingdomCredits",
        );
      case 'e59aa87c-4cbf-517a-5983-6e81511be9b7':
        return FlutterI18n.translate(
          context,
          "Page.AuthClient.currencies.RadianitePoints",
        );
      case 'f08d4ae3-939c-4576-ab26-09ce1f23bb37':
        return FlutterI18n.translate(
          context,
          "Page.AuthClient.currencies.FreeAgent",
        );
      default:
        return FlutterI18n.translate(
          context,
          "Page.AuthClient.currencies.Unowned",
        );
    }
  }

  String? _extractTokenFromUrl(String url, String tokenKey) {
    final uri = Uri.parse(url);
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final params = Uri.splitQueryString(fragment);
      return params[tokenKey];
    }
    if (uri.queryParameters.containsKey(tokenKey)) {
      return uri.queryParameters[tokenKey];
    }
    return null;
  }
}
