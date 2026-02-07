package com.arcsoftfacern.facedb.entity;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "face")
public class FaceEntity {
    @PrimaryKey(autoGenerate = true)
    public int id;

    @ColumnInfo(name = "user_id")
    public String userId;

    @ColumnInfo(name = "feature_data")
    public byte[] featureData;

    @ColumnInfo(name = "register_time")
    public long registerTime;

    public FaceEntity(String userId, byte[] featureData) {
        this.userId = userId;
        this.featureData = featureData;
        this.registerTime = System.currentTimeMillis();
    }
}
