
module.exports = {
  purge: ['./src/**/*.{js,jsx,ts,tsx}', './public/index.html'],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      color: {
        'regal-blue': '#243c5a',
        navy: {
          100: '#5E2BF6',
          200: '#42389D',
          300: '#EFEAFE',
        },
        green: {
          100: '#ECFCF4',
          200: '#27B76F',
          300: '#43E296',
        },
        blue: {
          100: '#5C89FF',
          200: '#2A64F6',
          300: '#2355CF',
        }
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
