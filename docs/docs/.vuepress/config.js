module.exports = {
  base: '/',
  locales: {
    '/docs/en-US/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight script language written in Dart for embedding in Flutter apps.',
    },
    '/docs/zh-Hans/': {
      lang: 'zh-Hans',
      title: '河图脚本语言',
      description: '专为 Flutter 打造的轻量型嵌入式脚本语言。',
    },
  },
  themeConfig: {
    locales: {
      '/docs/en-US/': {
        selectText: 'Languages',
        label: 'English',
        editLinkText: 'Edit this page on GitHub',
        navbar: [
          {
            text: 'Guide',
            link: '/docs/en-US/',
          },
          {
            text: 'Language',
            link: '/docs/en-US/syntax/introduction/',
          },
          {
            text: 'API Reference',
            children: [
              {
                text: 'Dart APIs',
                link: '/docs/en-US/api_reference/dart/',
              },
              {
                text: 'Hetu APIs',
                link: '/docs/en-US/api_reference/hetu/',
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
          '/docs/en-US/syntax/': [
            {
              text: 'Introduction',
              link: '/docs/en-US/syntax/introduction/',
            },
            {
              text: 'Identifier & keywords',
              link: '/docs/en-US/syntax/identifier/',
            },
            {
              text: 'Builtin types',
              link: '/docs/en-US/syntax/builtin_types/',
            },
            {
              text: 'Operators',
              link: '/docs/en-US/syntax/operators/',
            },
            {
              text: 'Variable',
              link: '/docs/en-US/syntax/variable/',
            },
            {
              text: 'Control flow',
              link: '/docs/en-US/syntax/control_flow/',
            },
            {
              text: 'Function',
              link: '/docs/en-US/syntax/function/',
            },
            {
              text: 'Enum',
              link: '/docs/en-US/syntax/enum/',
            },
            {
              text: 'Class',
              link: '/docs/en-US/syntax/class/',
            },
            {
              text: 'Struct',
              link: '/docs/en-US/syntax/struct/',
            },
            {
              text: 'Type system',
              link: '/docs/en-US/syntax/type_system/',
            },
            {
              text: 'Future, async & await',
              link: '/docs/en-US/syntax/future/',
            },
            {
              text: 'Import & export',
              link: '/docs/en-US/syntax/import/',
            },
            {
              text: 'Strict mode',
              link: '/docs/en-US/syntax/strict_mode/',
            },
            {
              text: 'Assert & error',
              link: '/docs/en-US/syntax/error/',
            },
          ],
          '/docs/en-US/api_reference/': [
            {
              text: 'Dart APIs',
              link: '/docs/en-US/api_reference/dart/',
            },
            {
              text: 'Hetu APIs',
              link: '/docs/en-US/api_reference/hetu/',
            },
          ],
          '/docs/en-US/': [
            {
              text: 'Introduction',
              link: '/docs/en-US/',
            },
            {
              text: 'Installation',
              link: '/docs/en-US/installation/',
            },
            {
              text: 'Package & Module',
              link: '/docs/en-US/package/',
            },
            {
              text: 'Communicating with Dart',
              link: '/docs/en-US/binding/',
            },
            {
              text: 'Command line tool',
              link: '/docs/en-US/command_line_tool/',
            },
            {
              text: 'Analyzer',
              link: '/docs/en-US/analyzer/',
            },
            {
              text: 'Language',
              link: '/docs/en-US/syntax/introduction/',
            },
            {
              text: 'API Reference',
              link: '/docs/en-US/api_reference/dart/',
            },
            {
              text: 'Implementation detail',
              link: '/docs/en-US/implementation_detail/',
            },
          ],
        },
      },
      '/docs/zh-Hans/': {
        selectText: '语言',
        label: '简体中文',
        editLinkText: '在 GitHub 上编辑这个页面',
        navbar: [
          {
            text: '入门',
            link: '/docs/zh-Hans/',
          },
          {
            text: '语法',
            link: '/docs/zh-Hans/syntax/introduction/',
          },
          {
            text: 'API 参考',
            children: [
              {
                text: 'Dart API',
                link: '/docs/zh-Hans/api_reference/dart/',
              },
              {
                text: '河图 API',
                link: '/docs/zh-Hans/api_reference/hetu/',
              },
            ],
          },
          {
            text: 'IDE 工具',
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
          '/docs/zh-Hans/syntax/': [
            {
              text: '语法简介',
              link: '/docs/zh-Hans/syntax/introduction/',
            },
            {
              text: '标识符和关键字',
              link: '/docs/zh-Hans/syntax/identifier/',
            },
            {
              text: '内置类型',
              link: '/docs/zh-Hans/syntax/builtin_types/',
            },
            {
              text: '特殊语法和操作符',
              link: '/docs/zh-Hans/syntax/operators/',
            },
            {
              text: '变量',
              link: '/docs/zh-Hans/syntax/variable/',
            },
            {
              text: '控制流程',
              link: '/docs/zh-Hans/syntax/control_flow/',
            },
            {
              text: '函数',
              link: '/docs/zh-Hans/syntax/function/',
            },
            {
              text: '枚举类',
              link: '/docs/zh-Hans/syntax/enum/',
            },
            {
              text: '类',
              link: '/docs/zh-Hans/syntax/class/',
            },
            {
              text: '结构体',
              link: '/docs/zh-Hans/syntax/struct/',
            },
            {
              text: '类型系统',
              link: '/docs/zh-Hans/syntax/type_system/',
            },
            {
              text: '异步操作',
              link: '/docs/zh-Hans/syntax/future/',
            },
            {
              text: '导入其他代码文件',
              link: '/docs/zh-Hans/syntax/import/',
            },
            {
              text: '严格模式',
              link: '/docs/zh-Hans/syntax/strict_mode/',
            },
            {
              text: '断言和错误处理',
              link: '/docs/zh-Hans/syntax/error/',
            },
          ],
          '/docs/zh-Hans/api_reference/': [
            {
              text: 'Dart API',
              link: '/docs/zh-Hans/api_reference/dart/',
            },
            {
              text: '河图 API',
              link: '/docs/zh-Hans/api_reference/hetu/',
            },
          ],
          '/docs/zh-Hans/': [
            {
              text: '快速上手',
              link: '/docs/zh-Hans/',
            },
            {
              text: '安装',
              link: '/docs/zh-Hans/installation/',
            },
            {
              text: '代码模块',
              link: '/docs/zh-Hans/package/',
            },
            {
              text: '和 Dart 代码交互',
              link: '/docs/zh-Hans/binding/',
            },
            {
              text: '命令行工具',
              link: '/docs/zh-Hans/command_line_tool/',
            },
            {
              text: '语法分析工具',
              link: '/docs/zh-Hans/analyzer/',
            },
            {
              text: '河图的语法',
              link: '/docs/zh-Hans/syntax/introduction/',
            },
            {
              text: 'API 参考',
              link: '/docs/zh-Hans/api_reference/dart/',
            },
            {
              text: '语言实现细节',
              link: '/docs/zh-Hans/implementation_detail/',
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
          '/docs/en-US/': {
            placeholder: 'Search',
          },
          '/docs/zh-CN/': {
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
  ],
};
