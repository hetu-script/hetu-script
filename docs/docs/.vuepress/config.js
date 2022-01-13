module.exports = {
  base: '/',
  locales: {
    '/docs/en-US/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight script language written in Dart for embedding in Flutter apps.',
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
            link: '/docs/en-US/syntax/',
          },
          {
            text: 'API Reference',
            link: '/docs/en-US/api_reference/',
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
              text: 'Identifier & keywords',
              link: '/docs/en-US/syntax/identifier/',
            },
            {
              text: 'Semicolon',
              link: '/docs/en-US/syntax/semicolon/',
            },
            {
              text: 'Comment',
              link: '/docs/en-US/syntax/comment/',
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
              text: 'Namespace',
              link: '/docs/en-US/syntax/namespace/',
            },
            {
              text: 'Struct',
              link: '/docs/en-US/syntax/struct/',
            },
            {
              text: 'Private',
              link: '/docs/en-US/syntax/private/',
            },
            {
              text: 'Type system',
              link: '/docs/en-US/syntax/type_system/',
            },
            {
              text: 'Strict mode',
              link: '/docs/en-US/syntax/strict_mode/',
            },
            {
              text: 'Future, async & await',
              link: '/docs/en-US/syntax/future/',
            },
            {
              text: 'Module, import & export',
              link: '/docs/en-US/syntax/module/',
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
              link: '/docs/en-US/language/',
            },
            {
              text: 'API Reference',
              link: '/docs/en-US/api_reference/',
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
