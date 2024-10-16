const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './node_modules/flowbite/**/*.js'
  ],
  plugins : [
    require('flowbite/plugin')
  ],
  darkMode: 'false',
  theme: {
    colors: {
        primary: colors.slate
    },
    fontFamily: {
      'body': ['Geist'],
      'sans': ['Geist']
    }
  }
}
