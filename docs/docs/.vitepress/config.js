module.exports = {
  base: '/',
  dest: './public/docs',
  bundler: '@vuepress/vite',
  title: 'Hetu Script Language',
  locales: {
    '/en-US/': {
      lang: 'en-US',
      title: 'Hetu Script Language',
      description:
        'A lightweight script language written in Dart for embedding in Flutter apps.',
    },
    '/zh-Hans/': {
      lang: 'zh-Hans',
      title: '河图脚本语言',
      description: '专为 Flutter APP 打造的嵌入式脚本语言。',
    },
  },
  themeConfig: {
    locales: {
      '/zh-Hans/': {
        selectText: '选择语言',
        label: '简体中文',
        editLinkText: '在 GitHub 上编辑此页',
        nav: [{ text: '介绍', link: '/zh-Hans/' }],
      },
      '/en-US/': {
        selectText: 'Languages',
        label: 'English',
        editLinkText: 'Edit this page on GitHub',
        nav: [
          { text: 'Introduction', link: '/en-US/' },
          { text: 'Syntax', link: '/en-US/syntax/' },
          {
            text: 'Tool',
            items: [
              { text: 'Binding', link: '/en-US/binding/' },
              {
                text: 'IDE Extension',
                link:
                  'https://marketplace.visualstudio.com/items?itemName=hetu-script.hetuscript',
              },
            ],
          },
          {
            text: 'Referrence',
            items: [
              {
                text: 'Operator Precedence',
                link: '/en-US/operator_precedence/',
              },
              {
                text: 'Bytecode Specification',
                link: '/en-US/bytecode_specification/',
              },
            ],
          },
        ],
      },
    },
  },
};
