module.exports = {
  dependency: {
    platforms: {
      ios: {
        // ✅ 告诉 RN：podspec 在 ios/ 目录
        podspecPath: 'ios/RnArcFace.podspec',
      },
      android: {},
    },
  },
};
