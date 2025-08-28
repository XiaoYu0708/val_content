package com.example.valcontent;

import android.util.Log;

public class MemoryPageSizeChecker {
    private static final String TAG = "MemoryPageSizeChecker";
    
    static {
        System.loadLibrary("val_content");
    }
    
    public native long getPageSize();
    
    public void checkPageSize() {
        long pageSize = getPageSize();
        Log.i(TAG, "Current page size: " + pageSize + " bytes");
        
        if (pageSize == 16384) {
            Log.i(TAG, "Running on 16KB page size system");
        } else if (pageSize == 4096) {
            Log.i(TAG, "Running on 4KB page size system");
        } else {
            Log.w(TAG, "Unexpected page size: " + pageSize);
        }
    }
    
    public boolean is16KBPageSize() {
        return getPageSize() == 16384;
    }
}
