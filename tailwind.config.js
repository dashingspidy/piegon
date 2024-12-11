const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/views/components/**/*.html.erb',
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
        primary: colors.slate,
        "prim": "#E1D6DC",
        "link-water": "#C9CCDC",
        "lavender-gray": "#C0C8DB",
        "ship-cove": "#838BAD",
        "chambray": "#464e7f"
    },
    fontFamily: {
      'sans': ['Geist'],
      'logo': ['Borel'],
    },
    extend: {
      animation: {
        fadeout: 'fadeout 1.5s ease-out'
      },
      keyframes: {
        fadeout: {
          '0%': { opacity: '1'},
          '100%': { opacity: '0'}
        }
      }
    }
  }
}
