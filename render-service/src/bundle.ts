import path from "node:path";
import { bundle } from "@remotion/bundler";

let bundleLocation: string | null = null;

/**
 * Bundles the Remotion project on startup and caches the result.
 * Uses REMOTION_BUNDLE_PATH env var to locate the remotion source
 * (default: "../remotion" relative to this service's root).
 */
export async function initBundle(): Promise<void> {
  const remotionRoot = process.env.REMOTION_BUNDLE_PATH
    ? path.resolve(process.env.REMOTION_BUNDLE_PATH)
    : path.resolve(import.meta.dirname, "../../remotion");

  const entryPoint = path.join(remotionRoot, "src", "index.ts");

  console.log(`[bundle] Bundling Remotion project from: ${entryPoint}`);

  bundleLocation = await bundle({
    entryPoint,
    rootDir: remotionRoot,
    enableCaching: false,
    webpackOverride: (config) => ({
      ...config,
      resolve: {
        ...config.resolve,
        alias: {
          ...(typeof config.resolve?.alias === "object" && !Array.isArray(config.resolve.alias)
            ? config.resolve.alias
            : {}),
          "remotion$": path.join(
            remotionRoot,
            "node_modules",
            "remotion",
            "dist",
            "esm",
            "index.mjs"
          ),
        },
      },
    }),
    onProgress: (progress: number) => {
      if (progress % 10 === 0) {
        console.log(`[bundle] Progress: ${progress}%`);
      }
    },
  });

  console.log(`[bundle] Bundle created at: ${bundleLocation}`);
}

/**
 * Returns the cached bundle location.
 * Throws if initBundle() has not been called yet.
 */
export function getBundleLocation(): string {
  if (!bundleLocation) {
    throw new Error(
      "Bundle not initialized. Call initBundle() before getBundleLocation()."
    );
  }
  return bundleLocation;
}
