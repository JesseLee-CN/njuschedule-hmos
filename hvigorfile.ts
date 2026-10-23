import fs from 'fs';
import path from 'path';
import { hvigor, HvigorNode } from '@ohos/hvigor';
import { appTasks, OhosAppContext, OhosPluginId } from '@ohos/hvigor-ohos-plugin';

interface ExternalSigningMaterial {
  certpath: string;
  keyAlias: string;
  keyPassword: string;
  profile: string;
  signAlg: string;
  storeFile: string;
  storePassword: string;
}

interface ExternalSigningConfig {
  name: string;
  type: string;
  material: ExternalSigningMaterial;
}

interface ProductSigningConfigs {
  [productName: string]: string;
}

interface ExternalSigningConfigFile {
  signingConfigs: ExternalSigningConfig[];
  productSigningConfigs: ProductSigningConfigs;
}

const externalSigningConfigPath = path.resolve(__dirname, 'external-signing-config.json');

function isObject(value: unknown): value is object {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0;
}

function isSigningMaterial(value: unknown): value is ExternalSigningMaterial {
  if (!isObject(value)) {
    return false;
  }
  const material = value as Partial<ExternalSigningMaterial>;
  return isNonEmptyString(material.certpath) &&
    isNonEmptyString(material.keyAlias) &&
    isNonEmptyString(material.keyPassword) &&
    isNonEmptyString(material.profile) &&
    isNonEmptyString(material.signAlg) &&
    isNonEmptyString(material.storeFile) &&
    isNonEmptyString(material.storePassword);
}

function isSigningConfig(value: unknown): value is ExternalSigningConfig {
  if (!isObject(value)) {
    return false;
  }
  const signingConfig = value as Partial<ExternalSigningConfig>;
  return isNonEmptyString(signingConfig.name) &&
    isNonEmptyString(signingConfig.type) &&
    isSigningMaterial(signingConfig.material);
}

function isProductSigningConfigs(value: unknown): value is ProductSigningConfigs {
  if (!isObject(value)) {
    return false;
  }
  return Object.values(value).every((signingConfigName: unknown) => isNonEmptyString(signingConfigName));
}

function readExternalSigningConfig(): ExternalSigningConfigFile | undefined {
  if (!fs.existsSync(externalSigningConfigPath)) {
    return undefined;
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(fs.readFileSync(externalSigningConfigPath, 'utf8')) as unknown;
  } catch {
    throw new Error('external-signing-config.json must contain valid JSON.');
  }

  if (!isObject(parsed)) {
    throw new Error('external-signing-config.json must contain an object.');
  }
  const externalConfig = parsed as Partial<ExternalSigningConfigFile>;
  if (!Array.isArray(externalConfig.signingConfigs) ||
    externalConfig.signingConfigs.length === 0 ||
    !externalConfig.signingConfigs.every(isSigningConfig) ||
    !isProductSigningConfigs(externalConfig.productSigningConfigs)) {
    throw new Error('external-signing-config.json does not match the required signing schema.');
  }

  const signingConfigNames = new Set(externalConfig.signingConfigs.map((config: ExternalSigningConfig) => config.name));
  if (signingConfigNames.size !== externalConfig.signingConfigs.length ||
    !Object.values(externalConfig.productSigningConfigs).every((name: string) => signingConfigNames.has(name))) {
    throw new Error('external-signing-config.json contains duplicate or unknown signing configuration names.');
  }

  return externalConfig as ExternalSigningConfigFile;
}

hvigor.afterNodeEvaluate((hvigorNode: HvigorNode) => {
  const context = hvigorNode.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext | undefined;
  if (context === undefined) {
    return;
  }

  const externalConfig = readExternalSigningConfig();
  if (externalConfig === undefined) {
    return;
  }

  const buildProfile = context.getBuildProfileOpt();
  buildProfile.app.signingConfigs = externalConfig.signingConfigs;
  const products = buildProfile.app.products ?? [];
  for (const [productName, signingConfigName] of Object.entries(externalConfig.productSigningConfigs)) {
    const product = products.find((candidate) => candidate.name === productName);
    if (product === undefined) {
      throw new Error(`external-signing-config.json references unknown product '${productName}'.`);
    }
    product.signingConfig = signingConfigName;
  }
  context.setBuildProfileOpt(buildProfile);
});

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
}
