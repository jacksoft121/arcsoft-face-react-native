package com.arcsoftfacern.facedb;

import android.content.Context;

import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;

import com.arcsoftfacern.facedb.dao.FaceDao;
import com.arcsoftfacern.facedb.entity.FaceEntity;

@Database(entities = {FaceEntity.class}, version = 1, exportSchema = false)
public abstract class FaceDatabase extends RoomDatabase {
    public abstract FaceDao faceDao();

    private static volatile FaceDatabase INSTANCE;

    public static FaceDatabase getInstance(Context context) {
        if (INSTANCE == null) {
            synchronized (FaceDatabase.class) {
                if (INSTANCE == null) {
                    INSTANCE = Room.databaseBuilder(context.getApplicationContext(),
                            FaceDatabase.class, "arcsoft_face_db")
                            .allowMainThreadQueries() // For simplicity in this demo, allow main thread. In prod, use async.
                            .build();
                }
            }
        }
        return INSTANCE;
    }
}
