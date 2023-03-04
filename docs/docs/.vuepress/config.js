import { path } from '@vuepress/utils';
import { defineUserConfig } from 'vuepress';
import { defaultTheme } from '@vuepress/theme-default';
import { googleAnalyticsPlugin } from '@vuepress/plugin-google-analytics';
import { registerComponentsPlugin } from '@vuepress/plugin-register-components';
import { searchPlugin } from '@vuepress/plugin-search';

export default defineUserConfig({
  base: '/docs/',
  locales: {
    '/en-US/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight scripting language written in Dart for embedding in Flutter apps.',
    },
    '/zh-Hans/': {
      lang: 'zh-Hans',
      title: '河图脚本语言',
      description: '专为 Flutter 打造的轻量型嵌入式脚本语言。',
    },
  },
  theme: defaultTheme({
    locales: {
      '/en-US/': {
        selectLanguageText: 'Select languages',
        selectLanguageName: 'English',
        navbar: [
          {
            text: 'Guide',
            link: '/en-US/guide/',
          },
          {
            text: 'Grammar',
            link: '/en-US/grammar/',
          },
          {
            text: 'API Reference',
            children: [
              {
                text: 'Dart APIs',
                link: '/en-US/api_reference/dart/',
              },
              {
                text: 'Hetu APIs',
                link: '/en-US/api_reference/hetu/',
              },
            ],
          },
          {
            text: 'IDE Tool',
            children: [
              {
                text: 'VS Code extension',
                link: 'https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript',
              },
            ],
          },
          {
            text: 'Github',
            link: 'https://github.com/hetu-script/hetu-script',
          },
        ],
        sidebar: {
          '/en-US/guide/': [
            {
              text: 'Introduction',
              link: '/en-US/guide/',
            },
            {
              text: 'Installation',
              link: '/en-US/guide/installation/',
            },
            {
              text: 'Package & Module',
              link: '/en-US/guide/package/',
            },
            {
              text: 'Communicating with Dart',
              link: '/en-US/guide/binding/',
            },
            {
              text: 'Command line tool',
              link: '/en-US/guide/command_line_tool/',
            },
            {
              text: 'Analyzer',
              link: '/en-US/guide/analyzer/',
            },
            {
              text: 'Implementation detail',
              link: '/en-US/guide/implementation_detail/',
            },
          ],
          '/en-US/grammar/': [
            {
              text: 'Introduction',
              link: '/en-US/grammar/',
            },
            {
              text: 'Identifier & keywords',
              link: '/en-US/grammar/identifier/',
            },
            {
              text: 'Builtin types',
              link: '/en-US/grammar/builtin_types/',
            },
            {
              text: 'Operators',
              link: '/en-US/grammar/operators/',
            },
            {
              text: 'Variable',
              link: '/en-US/grammar/variable/',
            },
            {
              text: 'Control flow',
              link: '/en-US/grammar/control_flow/',
            },
            {
              text: 'Function',
              link: '/en-US/grammar/function/',
            },
            {
              text: 'Enum',
              link: '/en-US/grammar/enum/',
            },
            {
              text: 'Class',
              link: '/en-US/grammar/class/',
            },
            {
              text: 'Struct',
              link: '/en-US/grammar/struct/',
            },
            {
              text: 'Type system',
              link: '/en-US/grammar/type_system/',
            },
            {
              text: 'Future, async & await',
              link: '/en-US/grammar/future/',
            },
            {
              text: 'Import & export',
              link: '/en-US/grammar/import/',
            },
            {
              text: 'Strict mode',
              link: '/en-US/grammar/strict_mode/',
            },
            {
              text: 'Assert & error',
              link: '/en-US/grammar/error/',
            },
          ],
          '/en-US/api_reference/': [
            {
              text: 'Dart APIs',
              link: '/en-US/api_reference/dart/',
            },
            {
              text: 'Hetu APIs',
              link: '/en-US/api_reference/hetu/',
            },
          ],
        },
      },
      '/zh-Hans/': {
        selectLanguageText: '选择语言',
        selectLanguageName: '简体中文',
        editLinkText: '在 GitHub 上编辑这个页面',
        navbar: [
          {
            text: '指南',
            link: '/zh-Hans/guide/',
          },
          {
            text: '语法',
            link: '/zh-Hans/grammar/',
          },
          {
            text: 'API 参考',
            children: [
              {
                text: 'Dart API',
                link: '/zh-Hans/api_reference/dart/',
              },
              {
                text: '河图 API',
                link: '/zh-Hans/api_reference/hetu/',
              },
            ],
          },
          {
            text: 'IDE 工具',
            children: [
              {
                text: 'VS Code 扩展',
                link: 'https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript',
              },
            ],
          },
          {
            text: 'Github',
            link: 'https://github.com/hetu-script/hetu-script',
          },
        ],
        sidebar: {
          '/zh-Hans/': [
            {
              text: '简介',
              link: '/zh-Hans/guide/',
            },
            {
              text: '安装',
              link: '/zh-Hans/guide/installation/',
            },
            {
              text: '和 Dart 的交互',
              link: '/zh-Hans/guide/binding/',
            },
            {
              text: '代码模块',
              link: '/zh-Hans/guide/package/',
            },
            {
              text: '命令行工具',
              link: '/zh-Hans/guide/command_line_tool/',
            },
            {
              text: '语法分析工具',
              link: '/zh-Hans/guide/analyzer/',
            },
            {
              text: '语言实现细节',
              link: '/zh-Hans/guide/implementation_detail/',
            },
          ],
          '/zh-Hans/grammar/': [
            {
              text: '语法概要',
              link: '/zh-Hans/grammar/',
            },
            {
              text: '标识符和关键字',
              link: '/zh-Hans/grammar/identifier/',
            },
            {
              text: '内置类型',
              link: '/zh-Hans/grammar/builtin_types/',
            },
            {
              text: '特殊语法和操作符',
              link: '/zh-Hans/grammar/operators/',
            },
            {
              text: '变量',
              link: '/zh-Hans/grammar/variable/',
            },
            {
              text: '控制流程',
              link: '/zh-Hans/grammar/control_flow/',
            },
            {
              text: '函数',
              link: '/zh-Hans/grammar/function/',
            },
            {
              text: '枚举类',
              link: '/zh-Hans/grammar/enum/',
            },
            {
              text: '类',
              link: '/zh-Hans/grammar/class/',
            },
            {
              text: '结构体',
              link: '/zh-Hans/grammar/struct/',
            },
            {
              text: '类型系统',
              link: '/zh-Hans/grammar/type_system/',
            },
            {
              text: '异步操作',
              link: '/zh-Hans/grammar/future/',
            },
            {
              text: '导入其他代码文件',
              link: '/zh-Hans/grammar/import/',
            },
            {
              text: '严格模式',
              link: '/zh-Hans/grammar/strict_mode/',
            },
            {
              text: '错误和异常的处理',
              link: '/zh-Hans/grammar/error/',
            },
          ],
          '/zh-Hans/api_reference/': [
            {
              text: 'Dart API',
              link: '/zh-Hans/api_reference/dart/',
            },
            {
              text: '河图 API',
              link: '/zh-Hans/api_reference/hetu/',
            },
          ],
        },
      },
    },
  }),
  plugins: [
    // registerComponentsPlugin({
    //   componentsDir: path.resolve(__dirname, './components'),
    // }),
    googleAnalyticsPlugin({
      id: 'G-KFRTSHXYD5',
    }),
    searchPlugin({
      locales: {
        '/en-US/': {
          placeholder: 'Search...',
        },
        '/zh-Hans/': {
          placeholder: '搜索...',
        },
        getExtraFields: (page) => page.frontmatter.tags ?? [],
      },
    }),
  ],
});
