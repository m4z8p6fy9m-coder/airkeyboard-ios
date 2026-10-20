"""Deterministic, dependency-free Xcode project generation. Run from any directory."""
from pathlib import Path
import hashlib
import plistlib
import json
import struct
import zlib
import math
import random
import wave

ROOT = Path(__file__).resolve().parents[1]

def write(path, data):
    file = ROOT / path
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_bytes(data if isinstance(data, bytes) else data.encode())

def plist(path, value):
    write(path, plistlib.dumps(value, sort_keys=True))

def uid(value):
    return hashlib.sha256(value.encode()).hexdigest()[:24].upper()

def q(value):
    return json.dumps(str(value))

def generate_assets():
    # Original deterministic DSP: decaying filtered noise + sinusoidal transients.
    for index, pack in enumerate(['tactile', 'mechanical', 'pop', 'digital']):
        rng = random.Random(20261020 + index)
        duration = [0.035, 0.028, 0.045, 0.032][index]
        frequency = [430, 1800, 270, 1250][index]
        samples = []
        filtered = 0.0
        for n in range(int(44100 * duration)):
            t = n / 44100
            filtered = 0.65 * filtered + 0.35 * rng.uniform(-1, 1)
            envelope = math.exp(-t / (duration / 5)) * min(1, t / 0.001)
            tone = math.sin(2 * math.pi * (frequency * t + (100 * t*t if index == 3 else 0)))
            mix = [0.5, 0.85, 0.15, 0.08][index]
            value = (mix * filtered + (1 - mix) * tone) * envelope * 0.45
            # Fade to exact zero at tail to avoid a truncation click.
            value *= min(1, (duration - t) / 0.003)
            samples.append(round(value * 32767))
        path = ROOT / 'Resources' / (pack + '.wav')
        path.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(path), 'wb') as out:
            out.setparams((1, 2, 44100, 0, 'NONE', 'not compressed'))
            out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
    # Code-drawn original app icon: three rows of mint keys on an opaque ink surface.
    rows = bytearray()
    for y in range(1024):
        rows.append(0)
        for x in range(1024):
            color = (18 + y // 128, 27 + y // 100, 34 + y // 90)
            for row in range(3):
                for col in range(3):
                    left, top = 188 + col * 224, 200 + row * 208
                    width = 200 if row < 2 else (424 if col == 1 else 200)
                    if row == 2 and col == 2:
                        continue
                    dx = max(left + 30 - x, 0, x - (left + width - 30))
                    dy = max(top + 30 - y, 0, y - (top + 176 - 30))
                    if left <= x <= left + width and top <= y <= top + 176 and dx*dx + dy*dy <= 900:
                        color = (131, 229, 206) if row == 2 else (53, 76, 84)
            rows.extend(color)
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1024, 1024, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')
    write('App/Assets.xcassets/AppIcon.appiconset/icon.png', png)
    write('App/Assets.xcassets/AppIcon.appiconset/Contents.json', json.dumps({
        'images': [{'filename': 'icon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}],
        'info': {'author': 'AirKeyboard', 'version': 1}}, indent=2))
    write('App/Assets.xcassets/Contents.json', '{"info":{"author":"AirKeyboard","version":1}}\n')

def generate_configuration(group='group.org.example.airkeyboard', local_device=False):
    common = {'CFBundleDevelopmentRegion': 'en', 'CFBundleExecutable': '$(EXECUTABLE_NAME)',
              'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleInfoDictionaryVersion': '6.0',
              'CFBundleName': '$(PRODUCT_NAME)', 'CFBundleShortVersionString': '0.1.0', 'CFBundleVersion': '1',
              'AirKeyboardAppGroup': group, 'AirKeyboardStorageMode': 'local' if local_device else 'automatic'}
    plist('Config/App-Info.plist', dict(common, CFBundlePackageType='APPL', CFBundleDisplayName='AirKeyboard',
        UILaunchScreen={}, UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
        UIApplicationSceneManifest={'UIApplicationSupportsMultipleScenes': False},
        CFBundleURLTypes=[{'CFBundleURLName': 'AirKeyboard', 'CFBundleURLSchemes': ['airkeyboard']}],
        LSSupportsOpeningDocumentsInPlace=True))
    plist('Config/Keyboard-Info.plist', dict(common, CFBundlePackageType='XPC!', CFBundleDisplayName='AirKeyboard',
        NSExtension={'NSExtensionPointIdentifier': 'com.apple.keyboard-service',
                     'NSExtensionPrincipalClass': '$(PRODUCT_MODULE_NAME).KeyboardViewController',
                     'NSExtensionAttributes': {'IsASCIICapable': True, 'PrefersRightToLeft': False,
                                               'PrimaryLanguage': 'en-US', 'RequestsOpenAccess': True}}))
    plist('Config/Widgets-Info.plist', dict(common, CFBundlePackageType='XPC!', CFBundleDisplayName='AirKeyboard',
        NSExtension={'NSExtensionPointIdentifier': 'com.apple.widgetkit-extension'}))
    for name in ['App', 'Keyboard', 'Widgets']:
        plist(f'Config/{name}.entitlements', {} if local_device else {'com.apple.security.application-groups': [group]})
    # AppStorage stores the app's own appearance preference. No tracking or collected data.
    plist('Resources/PrivacyInfo.xcprivacy', {'NSPrivacyTracking': False, 'NSPrivacyCollectedDataTypes': [],
        'NSPrivacyAccessedAPITypes': [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
                                     'NSPrivacyAccessedAPITypeReasons': ['CA92.1']}]})

def generate_project(signing=None, local_device=False):
    objects = {}
    def obj(key, body):
        ident = uid(key)
        objects[ident] = '{ ' + body + ' };'
        return ident
    def arr(values):
        return '(' + ', '.join(values) + ')'
    def file(path, kind):
        return obj('file:' + path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(path)}; sourceTree = SOURCE_ROOT;')
    core = sorted(str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT / 'Shared/Core').glob('*.swift'))
    platform = sorted(str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT / 'Shared/Platform').glob('*.swift'))
    def swift_files(folder):
        return sorted(str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT / folder).glob('*.swift'))
    sources = {'AirKeyboard': core + platform + swift_files('App'),
               'AirKeyboardKeyboard': core + platform + swift_files('Keyboard'),
               'AirKeyboardWidgets': core + [p for p in platform if not p.endswith('SoundEngine.swift')] + swift_files('Widgets'),
               'AirKeyboardTests': core + swift_files('Tests/CoreTests'),
               'AirKeyboardUITests': swift_files('Tests/UITests')}
    resource_paths = ['Resources/PrivacyInfo.xcprivacy'] + [f'Resources/{p}.wav' for p in ['tactile', 'mechanical', 'pop', 'digital']]
    refs = {p: file(p, 'sourcecode.swift') for p in sorted(set(sum(sources.values(), [])))}
    for p in resource_paths:
        refs[p] = file(p, 'audio.wav' if p.endswith('.wav') else 'text.xml')
    refs['App/Assets.xcassets'] = file('App/Assets.xcassets', 'folder.assetcatalog')
    configs = sorted((ROOT / 'Config').glob('*'))
    config_refs = [file(str(p.relative_to(ROOT)).replace('\\', '/'), 'text.plist.xml') for p in configs]
    product_refs = {}
    for target in sources:
        ext = 'app' if target == 'AirKeyboard' else 'xctest' if target.endswith('Tests') else 'appex'
        kind = 'wrapper.application' if ext == 'app' else 'wrapper.cfbundle' if ext == 'xctest' else 'wrapper.app-extension'
        product_refs[target] = obj('product:' + target, f'isa = PBXFileReference; explicitFileType = {q(kind)}; path = {target}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;')
    products = obj('products', 'isa = PBXGroup; name = Products; sourceTree = "<group>"; children = ' + arr(list(product_refs.values())) + ';')
    main_group = obj('main_group', 'isa = PBXGroup; sourceTree = "<group>"; children = ' + arr(list(refs.values()) + config_refs + [products]) + ';')
    def config_list(key, settings):
        ids = []
        for mode in ['Debug', 'Release']:
            values = dict(settings)
            values['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if mode == 'Debug' else '-O'
            values['DEBUG_INFORMATION_FORMAT'] = 'dwarf' if mode == 'Debug' else 'dwarf-with-dsym'
            if mode == 'Debug': values['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
            body = ' '.join(f'{k} = {q(v)};' for k, v in values.items())
            ids.append(obj(f'{key}:{mode}', f'isa = XCBuildConfiguration; name = {mode}; buildSettings = {{ {body} }};'))
        return obj(key + ':configs', 'isa = XCConfigurationList; buildConfigurations = ' + arr(ids) + '; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    project_settings = {'IPHONEOS_DEPLOYMENT_TARGET': '18.0', 'SDKROOT': 'iphoneos', 'SWIFT_VERSION': '5.0',
        'CLANG_ENABLE_MODULES': 'YES', 'CLANG_ENABLE_OBJC_ARC': 'YES', 'SWIFT_STRICT_CONCURRENCY': 'targeted',
        'ENABLE_USER_SCRIPT_SANDBOXING': 'YES'}
    project_configs = config_list('project', project_settings)
    for target, paths in sources.items():
        builds = [obj(f'build:{target}:{p}', f'isa = PBXBuildFile; fileRef = {refs[p]};') for p in paths]
        source_phase = obj(target + ':sources', 'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ' + arr(builds) + '; runOnlyForDeploymentPostprocessing = 0;')
        target_resources = [] if target.endswith('Tests') else (resource_paths if target != 'AirKeyboardWidgets' else resource_paths[:1])
        if target == 'AirKeyboard': target_resources = target_resources + ['App/Assets.xcassets']
        res_builds = [obj(f'resource:{target}:{p}', f'isa = PBXBuildFile; fileRef = {refs[p]};') for p in target_resources]
        resource_phase = obj(target + ':resources', 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ' + arr(res_builds) + '; runOnlyForDeploymentPostprocessing = 0;')
        frameworks = obj(target + ':frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
        phases = [source_phase, frameworks, resource_phase]
        dependencies = []
        if target == 'AirKeyboard':
            embed_builds = []
            for extension in ['AirKeyboardKeyboard', 'AirKeyboardWidgets']:
                embed_builds.append(obj('embed:' + extension, f'isa = PBXBuildFile; fileRef = {product_refs[extension]}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy, ); }};'))
                proxy = obj('proxy:' + extension, f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target:" + extension)}; remoteInfo = {extension};')
                dependencies.append(obj('dependency:' + extension, f'isa = PBXTargetDependency; target = {uid("target:" + extension)}; targetProxy = {proxy};'))
            phases.append(obj('embed_phase', 'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; name = "Embed App Extensions"; files = ' + arr(embed_builds) + '; runOnlyForDeploymentPostprocessing = 0;'))
        suffix = '' if target == 'AirKeyboard' else '.keyboard' if target.endswith('Keyboard') else '.widgets' if target.endswith('Widgets') else '.uitests' if target == 'AirKeyboardUITests' else '.tests'
        settings = {'PRODUCT_NAME': '$(TARGET_NAME)', 'PRODUCT_BUNDLE_IDENTIFIER': 'org.example.airkeyboard' + suffix,
                    'CODE_SIGN_STYLE': 'Automatic', 'DEVELOPMENT_TEAM': '', 'TARGETED_DEVICE_FAMILY': '1,2',
                    'SWIFT_EMIT_LOC_STRINGS': 'YES', 'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'}
        if target.endswith('Tests'):
            settings['GENERATE_INFOPLIST_FILE'] = 'YES'
            settings['SKIP_INSTALL'] = 'YES'
            if target == 'AirKeyboardUITests':
                settings['TEST_TARGET_NAME'] = 'AirKeyboard'
        else:
            short = 'App' if target == 'AirKeyboard' else 'Keyboard' if target.endswith('Keyboard') else 'Widgets'
            settings.update({'INFOPLIST_FILE': f'Config/{short}-Info.plist', 'CODE_SIGN_ENTITLEMENTS': f'Config/{short}.entitlements'})
            if local_device:
                settings['CODE_SIGN_ENTITLEMENTS'] = ''
            if short != 'App': settings.update({'APPLICATION_EXTENSION_API_ONLY': 'YES', 'SKIP_INSTALL': 'YES'})
            else: settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
        if signing and target in signing:
            settings.update(signing[target])
        cfg = config_list(target, settings)
        product_type = 'application' if target == 'AirKeyboard' else 'bundle.ui-testing' if target == 'AirKeyboardUITests' else 'bundle.unit-test' if target.endswith('Tests') else 'app-extension'
        obj('target:' + target, f'isa = PBXNativeTarget; name = {target}; productName = {target}; productType = "com.apple.product-type.{product_type}"; productReference = {product_refs[target]}; buildConfigurationList = {cfg}; buildPhases = {arr(phases)}; buildRules = (); dependencies = {arr(dependencies)};')
    obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main_group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {arr([uid("target:" + t) for t in sources])};')
    body = '\n'.join(f'\t\t{k} = {v}' for k, v in sorted(objects.items()))
    write('AirKeyboard.xcodeproj/project.pbxproj', '// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + body + '\n\t};\n\trootObject = ' + uid('project') + ';\n}\n')
    def buildable(t):
        ext = 'app' if t == 'AirKeyboard' else 'xctest'
        return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:" + t)}" BuildableName="{t}.{ext}" BlueprintName="{t}" ReferencedContainer="container:AirKeyboard.xcodeproj"/>'
    write('AirKeyboard.xcodeproj/xcshareddata/xcschemes/AirKeyboard.xcscheme', f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildable('AirKeyboard')}</BuildActionEntry>
  <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{buildable('AirKeyboardTests')}</BuildActionEntry>
  <BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{buildable('AirKeyboardUITests')}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildable('AirKeyboardTests')}</TestableReference><TestableReference skipped="NO">{buildable('AirKeyboardUITests')}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildable('AirKeyboard')}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildable('AirKeyboard')}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--local-device', action='store_true', help='Remove App Group entitlements for optional free Personal Team testing; settings stay per-target')
    args = parser.parse_args()
    generate_assets()
    generate_configuration(local_device=args.local_device)
    generate_project(local_device=args.local_device)
    print('Generated Xcode project, plists, icon, and original WAV assets.')
