module.exports = {
  base: '/',
  title: 'Hetu Script Language',
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
        nav: [
          {
            text: 'Tool',
            items: [
              {
                text: 'IDE Extension',
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
};
