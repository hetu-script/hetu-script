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
            text: 'Tool',
            children: [
              {
                text: 'VSCode Extension',
                link: 'https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript',
                activeMatch: '/',
              },
            ],
          },
          {
            text: 'Github',
            link: 'https://github.com/hetu-script/hetu-script',
          },
        ],
        sidebar: {
          '/': [
            {
              text: 'Introduction',
              link: '/docs/en-US/',
            },
            {
              text: 'Installation',
              link: '/docs/en-US/installation/',
            },
            {
              text: 'Common API',
              link: '/docs/en-US/common_api/',
            },
            {
              text: 'Language',
              link: '/docs/en-US/syntax/',
            },
            {
              text: 'Module import & export',
              link: '/docs/en-US/module/',
            },
            {
              text: 'Communicating with Dart',
              link: '/docs/en-US/binding/',
            },
            {
              text: 'Advanced topics',
              link: '/docs/en-US/advanced/',
            },
            {
              text: 'Analyzer',
              link: '/docs/en-US/analyzer/',
            },
            {
              text: 'Command line tool',
              link: '/docs/en-US/command_line_tool/',
            },
          ],
        },
      },
    },
  },
  plugins: [
    [
      '@vuepress/docsearch',
      {
        apiKey: '29e16def0c1d45632b141951e56e7189',
        indexName: 'hetu',
        locales: {
          '/': {
            placeholder: 'Search Documentation',
          },
          '/zh/': {
            placeholder: '搜索文档',
          },
        },
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
