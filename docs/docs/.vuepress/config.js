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
