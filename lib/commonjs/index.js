"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  ArcFaceRegistry: true,
  useArcFace: true,
  arcFace: true
};
Object.defineProperty(exports, "ArcFaceRegistry", {
  enumerable: true,
  get: function () {
    return _ArcFaceRegistry.ArcFaceRegistry;
  }
});
Object.defineProperty(exports, "arcFace", {
  enumerable: true,
  get: function () {
    return _arcFacePlugin.arcFace;
  }
});
Object.defineProperty(exports, "useArcFace", {
  enumerable: true,
  get: function () {
    return _useArcFace.useArcFace;
  }
});
var _types = require("./types");
Object.keys(_types).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _types[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _types[key];
    }
  });
});
var _ArcFaceRegistry = require("./ArcFaceRegistry");
var _useArcFace = require("./useArcFace");
var _arcFacePlugin = require("./arcFacePlugin");
//# sourceMappingURL=index.js.map