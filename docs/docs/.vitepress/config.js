module.exports = {
  base: '/',
  title: 'Hetu Script Language',
  locales: {
    '/en-US/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight script language written in Dart for embedding in Flutter apps.',
    },
  },
  themeConfig: {
    locales: {
      '/en-US/': {
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
        ],
        sidebar: {
          '/': [
            {
              text: 'Introduction',
              link: '/en-US/introduction/',
            },
            {
              text: 'Installation',
              link: '/en-US/installation/',
            },
            {
              text: 'Common API',
              link: '/en-US/common_api/',
            },
            {
              text: 'Language',
              link: '/en-US/syntax/',
            },
            {
              text: 'Module import & export',
              link: '/en-US/module/',
            },
            {
              text: 'Communicating with Dart',
              link: '/en-US/binding/',
            },
            {
              text: 'Advanced topics',
              link: '/en-US/advanced/',
            },
            {
              text: 'Analyzer',
              link: '/en-US/analyzer/',
            },
            {
              text: 'Command line tool',
              link: '/en-US/command_line_tool/',
            },
          ],
        },
      },
    },
  },
};
