package com.arcsoftfacern;

import java.util.*;

public class ArcsoftFaceDB {
    private final Map<String, String> db = new HashMap<>();

    public void put(String name, String feature) {
        db.put(name, feature);
    }

    public void remove(String name) {
        db.remove(name);
    }

    public List<Map<String, Object>> search(String feature, int topN) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (String k : db.keySet()) {
            Map<String, Object> m = new HashMap<>();
            m.put("name", k);
            m.put("score", 0.9f);
            list.add(m);
        }
        return list;
    }
}
