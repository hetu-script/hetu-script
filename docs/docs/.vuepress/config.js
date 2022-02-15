const { path } = require('@vuepress/utils');

module.exports = {
  base: '/script/',
  locales: {
    '/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight script language written in Dart for embedding in Flutter apps.',
    },
    '/zh-Hans/': {
      lang: 'zh-Hans',
      title: '河图脚本语言',
      description: '专为 Flutter 打造的轻量型嵌入式脚本语言。',
    },
  },
  themeConfig: {
    locales: {
      '/': {
        selectLanguageText: 'Select languages',
        selectLanguageName: 'English',
        navbar: [
          {
            text: 'Guide',
            link: '/guide/installation/',
          },
          {
            text: 'Language',
            link: '/syntax/introduction/',
          },
          {
            text: 'API Reference',
            children: [
              {
                text: 'Dart APIs',
                link: '/api_reference/dart/',
              },
              {
                text: 'Hetu APIs',
                link: '/api_reference/hetu/',
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
          '/guide/': [
            {
              text: 'Installation',
              link: '/guide/installation/',
            },
            {
              text: 'Package & Module',
              link: '/guide/package/',
            },
            {
              text: 'Communicating with Dart',
              link: '/guide/binding/',
            },
            {
              text: 'Command line tool',
              link: '/guide/command_line_tool/',
            },
            {
              text: 'Analyzer',
              link: '/guide/analyzer/',
            },
            {
              text: 'Implementation detail',
              link: '/guide/implementation_detail/',
            },
          ],
          '/syntax/': [
            {
              text: 'Introduction',
              link: '/syntax/introduction/',
            },
            {
              text: 'Identifier & keywords',
              link: '/syntax/identifier/',
            },
            {
              text: 'Builtin types',
              link: '/syntax/builtin_types/',
            },
            {
              text: 'Operators',
              link: '/syntax/operators/',
            },
            {
              text: 'Variable',
              link: '/syntax/variable/',
            },
            {
              text: 'Control flow',
              link: '/syntax/control_flow/',
            },
            {
              text: 'Function',
              link: '/syntax/function/',
            },
            {
              text: 'Enum',
              link: '/syntax/enum/',
            },
            {
              text: 'Class',
              link: '/syntax/class/',
            },
            {
              text: 'Struct',
              link: '/syntax/struct/',
            },
            {
              text: 'Type system',
              link: '/syntax/type_system/',
            },
            {
              text: 'Future, async & await',
              link: '/syntax/future/',
            },
            {
              text: 'Import & export',
              link: '/syntax/import/',
            },
            {
              text: 'Strict mode',
              link: '/syntax/strict_mode/',
            },
            {
              text: 'Assert & error',
              link: '/syntax/error/',
            },
          ],
          '/api_reference/': [
            {
              text: 'Dart APIs',
              link: '/api_reference/dart/',
            },
            {
              text: 'Hetu APIs',
              link: '/api_reference/hetu/',
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
            link: '/zh-Hans/guide/installation/',
          },
          {
            text: '语法',
            link: '/zh-Hans/syntax/introduction/',
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
          '/zh-Hans/syntax/': [
            {
              text: '语法简介',
              link: '/zh-Hans/syntax/introduction/',
            },
            {
              text: '标识符和关键字',
              link: '/zh-Hans/syntax/identifier/',
            },
            {
              text: '内置类型',
              link: '/zh-Hans/syntax/builtin_types/',
            },
            {
              text: '特殊语法和操作符',
              link: '/zh-Hans/syntax/operators/',
            },
            {
              text: '变量',
              link: '/zh-Hans/syntax/variable/',
            },
            {
              text: '控制流程',
              link: '/zh-Hans/syntax/control_flow/',
            },
            {
              text: '函数',
              link: '/zh-Hans/syntax/function/',
            },
            {
              text: '枚举类',
              link: '/zh-Hans/syntax/enum/',
            },
            {
              text: '类',
              link: '/zh-Hans/syntax/class/',
            },
            {
              text: '结构体',
              link: '/zh-Hans/syntax/struct/',
            },
            {
              text: '类型系统',
              link: '/zh-Hans/syntax/type_system/',
            },
            {
              text: '异步操作',
              link: '/zh-Hans/syntax/future/',
            },
            {
              text: '导入其他代码文件',
              link: '/zh-Hans/syntax/import/',
            },
            {
              text: '严格模式',
              link: '/zh-Hans/syntax/strict_mode/',
            },
            {
              text: '断言和错误处理',
              link: '/zh-Hans/syntax/error/',
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
  },
  plugins: [
    [
      '@vuepress/plugin-search',
      {
        locales: {
          '/': {
            placeholder: 'Search',
          },
          '/zh-Hans/': {
            placeholder: '搜索',
          },
        },
        // allow searching the `tags` frontmatter
        getExtraFields: (page) => page.frontmatter.tags ?? [],
      },
    ],
    [
      '@vuepress/plugin-google-analytics',
      {
        id: 'G-KFRTSHXYD5',
      },
    ],
    [
      '@vuepress/register-components',
      {
        componentsDir: path.resolve(__dirname, './components'),
      },
    ],
  ],
};
