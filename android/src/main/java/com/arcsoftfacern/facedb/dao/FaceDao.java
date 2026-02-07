package com.arcsoftfacern.facedb.dao;

import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import com.arcsoftfacern.facedb.entity.FaceEntity;

import java.util.List;

@Dao
public interface FaceDao {
    @Query("SELECT * FROM face")
    List<FaceEntity> getAllFaces();

    @Query("SELECT * FROM face WHERE user_id = :userId LIMIT 1")
    FaceEntity getFaceByUserId(String userId);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    long insertFace(FaceEntity faceEntity);

    @Query("DELETE FROM face WHERE user_id = :userId")
    void deleteFaceByUserId(String userId);

    @Query("DELETE FROM face")
    void deleteAll();

    @Query("SELECT COUNT(*) FROM face")
    int getCount();
}
