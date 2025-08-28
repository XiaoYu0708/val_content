#ifndef MEMORY_UTILS_H
#define MEMORY_UTILS_H

#include <unistd.h>
#include <sys/mman.h>

class MemoryUtils {
public:
    static long getPageSize() {
        return sysconf(_SC_PAGESIZE);
    }
    
    static bool is16KBPageSize() {
        return getPageSize() == 16384;
    }
    
    // 使用動態記憶體分頁大小進行記憶體對齊
    static void* alignedAlloc(size_t size) {
        long pageSize = getPageSize();
        size_t alignedSize = ((size + pageSize - 1) / pageSize) * pageSize;
        return aligned_alloc(pageSize, alignedSize);
    }
    
    // 安全的記憶體映射
    static void* safeMemoryMap(size_t size, int prot, int flags) {
        long pageSize = getPageSize();
        size_t alignedSize = ((size + pageSize - 1) / pageSize) * pageSize;
        return mmap(nullptr, alignedSize, prot, flags, -1, 0);
    }
};

#endif // MEMORY_UTILS_H
