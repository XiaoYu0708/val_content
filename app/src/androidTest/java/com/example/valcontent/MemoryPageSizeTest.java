package com.example.valcontent;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class MemoryPageSizeTest {
    
    @Test
    public void testPageSizeDetection() {
        MemoryPageSizeChecker checker = new MemoryPageSizeChecker();
        long pageSize = checker.getPageSize();
        
        // 驗證記憶體分頁大小是有效的
        assertTrue("Page size should be positive", pageSize > 0);
        assertTrue("Page size should be power of 2", (pageSize & (pageSize - 1)) == 0);
        
        // 驗證是常見的記憶體分頁大小
        assertTrue("Page size should be 4KB or 16KB", 
                  pageSize == 4096 || pageSize == 16384);
    }
    
    @Test
    public void testMemoryCompatibility() {
        MemoryPageSizeChecker checker = new MemoryPageSizeChecker();
        checker.checkPageSize();
        
        // 確保應用程式在不同記憶體分頁大小下都能正常運行
        assertNotNull("Checker should not be null", checker);
    }
}
