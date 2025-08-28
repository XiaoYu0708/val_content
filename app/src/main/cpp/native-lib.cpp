#include <jni.h>
#include <string>
#include <android/log.h>
#include "memory_utils.h"

#define LOG_TAG "NativeLib"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT jlong JNICALL
Java_com_example_valcontent_MemoryPageSizeChecker_getPageSize(JNIEnv *env, jobject thiz) {
    long pageSize = MemoryUtils::getPageSize();
    LOGI("Page size: %ld bytes", pageSize);
    return static_cast<jlong>(pageSize);
}

// 示例：安全的記憶體分配函數
extern "C" JNIEXPORT jlong JNICALL
Java_com_example_valcontent_MemoryPageSizeChecker_allocateAlignedMemory(JNIEnv *env, jobject thiz, jlong size) {
    void* ptr = MemoryUtils::alignedAlloc(static_cast<size_t>(size));
    if (ptr == nullptr) {
        LOGI("Failed to allocate aligned memory");
        return 0;
    }
    LOGI("Allocated aligned memory at: %p", ptr);
    return reinterpret_cast<jlong>(ptr);
}
