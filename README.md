# arcsoft-face-react-native (source-only, no SDK binaries)

This package contains **only source code** for a React Native 0.78 New Architecture compatible Native Module,
wrapping ArcSoft ArcFace SDK for **iOS + Android**.

> You must copy ArcSoft SDK binaries into:
> - iOS: `ios/ArcSoftFace/` (frameworks / static libs from official iOS demo)
> - Android: `android/libs/` and `android/src/main/jniLibs/` (jar + so from official Android demo)

## Install

```bash
yarn add ./path/to/arcsoft-face-react-native
cd ios && pod install
```

## Usage

```ts
import { ArcSoftFace } from 'arcsoft-face-react-native';

await ArcSoftFace.init({ appId: 'xxx', sdkKey: 'yyy', maxFaceNum: 5 });
const res = await ArcSoftFace.detectFaces({ imagePath: '/path/to/image.jpg' });
```

## Mapping to official demos

See `DOCS/DEMO_MAPPING.md`.
