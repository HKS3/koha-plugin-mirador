import replace from '@rollup/plugin-replace';
import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import json from "@rollup/plugin-json";
import { terser } from "rollup-plugin-terser";
import babel from "@rollup/plugin-babel";

// to future readers
// I'm honestly not sure which of these options are necessary
// to make this bundle work and load in Koha.
// I've been furiously trying out many different combinations
// for about an hour, and this one works.
// It may have reduntant entries and be full of bad practices.
// Patches welcome.

export default {
  input: "./index.js",

  output: [
    {
      file: "dist/mirador.mjs",
      format: "esm",
      sourcemap: true
    },
  ],

  plugins: [
    resolve({ browser: true }),
    replace({
      'process.env.NODE_ENV': JSON.stringify('production')
    }),
    commonjs(),
    json(),
    babel({ babelHelpers: "bundled", presets: ["@babel/preset-react"] }),
    terser()
  ],

  external: []
};
