README（可直接复制使用）
# arcsoft-face-react-native 使用说明（含 TestScreen）

> 以你“编译成功3.zip”作为基线：这里是**按你当前 TS API**写的使用说明。

---

## 1) 安装

在业务项目里：

```bash
yarn add arcsoft-face-react-native
# or
npm i arcsoft-face-react-native

iOS
cd ios
pod install
cd ..


你的插件里集成了 ArcSoft iOS SDK（ArcSoftFaceEngine.framework）。
一般不需要业务工程再手动配置；如果你把 framework 放在业务工程而不是插件内，确保它被正确添加到 Link Binary With Libraries。

Android

通常 autolink 即可。

yarn android

2) TS API（你当前基线）

你的 src/index.ts 导出（关键）：

activateOnline(appId, sdkKey): Promise<boolean>

initEngine({ detectMode, maxFaceNum, scale, enableAge, enableGender, enableLiveness, enable3DAngle }): Promise<number>

unInitEngine(): Promise<number>

detectFacesNV21(nv21:number[], w:number, h:number): Promise<FaceInfo[]>

extractFeatureNV21(nv21:number[], w:number, h:number, face:FaceInfo): Promise<FaceFeature | null>

compareFeature(f1, f2): Promise<number>

getAgeNV21(nv21, w, h, faces): Promise<number[]>

getGenderNV21(nv21, w, h, faces): Promise<number[]>

getLivenessNV21(nv21, w, h, faces): Promise<number[]>

getFace3DAngleNV21(nv21, w, h, faces): Promise<Face3DAngle[]>

人脸库（内存）：

faceDBAdd(userId, feature, faceTag?): Promise<boolean>

faceDBSearch(feature, topN=1): Promise<FaceSearchItem[]>

faceDBCount(): Promise<number>

3) 验证功能用 TestScreen
依赖（TestScreen 用到）
yarn add react-native-vision-camera vision-camera-resize-plugin react-native-reanimated


并按 VisionCamera 官方要求完成权限与 iOS Pod/Android 配置。

使用

把 TestScreen.tsx 放到业务项目（例如 src/screens/TestScreen.tsx），然后在路由中进入该页面。

步骤建议：

先填 appId/sdkKey → 点「激活」

点 initEngine

摄像头对准人脸：页面会实时显示

人脸数

年龄/性别/活体

3D角（yaw/pitch/roll）

点「注册到DB」再点「检索DB」验证人脸库注册/检索

点「自对比」验证 compareFeature

4) 注意事项（很关键）

NV21 数据很大
TestScreen 为了“快速验证插件能力”，用 Array.from(Uint8Array) 把 NV21 送到 JS 线程，再调用 Native。
这不是生产最佳实践（会有性能/GC 压力）。

生产建议

如果你后续要做实时识别，建议把“帧处理/提特征/检索”尽量放在 native 或 JSI/Worklet（减少 JS 拷贝）。

或改为：JS 只控制流程，native 管 camera buffer 与识别闭环。

分数范围
有些 SDK compare 返回 0~1，有些返回 0~100。TestScreen 里做了兼容展示。

5) 发布 npm（你已经在做）

你已经 bob init + yarn build 成功了。

常规流程：

package.json 填好 name/version/main/module/types/files（bob 会帮你生成 lib）

yarn build

yarn link
yarn link /Users/jackxu/dlxcode/arcsoft-face-react-native
in metro.config.js  const lib_arcsoft  = path.resolve(root, '/Users/jackxu/dlxcode/arcsoft-face-react-native'); // 你的 link 包路径

package.json add "arcsoft-face-react-native": "portal://Users/jackxu/dlxcode/arcsoft-face-react-native",


yarn pack

npm login

npm publish

如果你是私有包：

用 scope：@your-scope/arcsoft-face-react-native

或设置 publishConfig.access=restricted
