const path = require('path');
const { VueLoaderPlugin } = require('vue-loader');
const webpack = require('webpack');

module.exports = {
  mode: 'development',
  context: path.join(__dirname, 'src'),
  entry: { app: './app.js' },
  output: {
    path: path.resolve(__dirname, 'public/js'),
    filename: '[name].bundle.js',
  },
  resolve: {
    modules: [path.resolve(__dirname, 'src'), 'node_modules'],
    alias: {
      vue: 'vue/dist/vue.esm-bundler.js',
    },
  },
  module: {
    rules: [
      {
        test: /\.m?js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
            plugins: ['@babel/plugin-transform-runtime', '@babel/plugin-proposal-optional-chaining'],
          },
        },
      },
      {
        test: /\.vue$/i,
        loader: 'vue-loader',
        options: {
          compilerOptions: {
            isCustomElement: (tag) => {
              return /^x-/.test(tag);
            },
          },
        },
      },
      {
        test: /\.css$/,
        use: [
          {
            loader: 'style-loader',
          },
          {
            loader: 'css-loader',
            options: {
              sourceMap: true,
              url: false,
            },
          },
        ],
      },
    ],
  },
  plugins: [
    // make sure to include the plugin!
    new VueLoaderPlugin(),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV' : JSON.stringify('development'),
      __VUE_OPTIONS_API__: true,
      __VUE_PROD_DEVTOOLS__: false,
    }),
  ],
};
