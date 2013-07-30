_ = require 'underscore'
fs = require 'fs'
csv = require 'csv'
async = require 'async'
undress = require 'undress'

hardcoded =
    1120: 21004 # Neder-Over-Heembeek
    1602: 23077 # Vlezenbeek
    1702: 23016 # Groot-Bijgaarden
    1853: 23025 # Strombeek-Bever
    3018: 24062 # Wijgmaal
    3391: 24135 # Meensel-Kiezegem
    3461: 24008 # Molenbeek-Wersbeek
    4101: 62096 # Jemeppe-Sur-Meuse
    4367: 64021 # Crisnée
    4720: 63040 # La Calamine
    4721: 63040 # Kelmis
    5352: 92097 # Ohey
    5571: 91013 # Wiesme
    6224: 52021 # Fleurus
    6462: 56016 # Chimay
    6762: 85045 # Virton
    7190: 55050 # Ecaussinnes
    7191: 55050 # Ecaussinnes
    7711: 54007 # Moeskroen
    7742: 57062 # Pecq
    7780: 54010 # Komen-Waasten
    7783: 54010 # Komen-Waasten
    7784: 54010 # Komen-Waasten
    7850: 55010 # Edingen
    7880: 51019 # Vloesberg
    9042: 44014 # Desteldonk
    9112: 46021 # Sinaai
    9180: 44045 # Moerbeke-waas


toTitleCase = (str) ->
    str.replace /\w\S*/g, (txt) ->
        txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()


async.parallel
    zipcodes: (cb) ->
        csv().from.stream(fs.createReadStream(__dirname + '/data/zipcodes.csv'), { delimiter: ';' }).to.array (data) -> cb(null, data)
    niscodes: (cb) ->
        csv().from.stream(fs.createReadStream(__dirname + '/data/niscodes.csv'), { delimiter: ';' }).to.array (data) -> cb(null, data)
, (err, vars) ->
    {zipcodes, niscodes} = vars


    niscodes = {}
    niscodes[city[0].toLowerCase().replace(/\*+$/, '')] = city[1] for city in vars.niscodes

    cities = []
    missing = []

    for zip in zipcodes
        [ zipCode, name, province ] = zip

        province = province.trim()
        
        if province == '' || province == 'Provincie'
            continue # Not a real city!

        province = 'Brussel' if province == 'Brussel (19 gemeenten)'
        name = 'Kessel-Lo' if name == 'Kessel Lo'
        name = 'Sint-Joost-ten-Node' if name == 'SINT-JOOST-TEN-NOODE' # Wrong name
        name = 'Noirefontaine' if name == 'Noirfontaine'

        city =
            name: name
            zipCode: zipCode
            province: province
            main: 0

        if city.name == city.name.toUpperCase()
            city.name = toTitleCase(city.name)
            city.main = 1

        nis = niscodes[name.toLowerCase()]
        if nis # Direct hit
            city.nisCode = nis
            cities.push(city)
        else
            missing.push(city)

    refilter = (fn) ->
        missing = _.filter missing, (city) ->
            nis = fn(city)
            if nis
                city.nisCode = nis
                cities.push(city)
                return false
            else
                return true

    findNisByZip = (req) ->
        for city in cities
            return city.nisCode if city.zipCode == req.zipCode

        return hardcoded[req.zipCode] if hardcoded[req.zipCode]

        return 0

    findNisByName = (req) ->
        name = undress(req.name)

        # Match start
        regex = new RegExp('^' + name, 'i')
        for city in vars.niscodes
            if city[0].match(regex)
                return city[1]

        # Match rest
        regex = new RegExp(name, 'i')
        for city in vars.niscodes
            if city[0].match(regex)
                return city[1]

        return 0

    refilter(findNisByZip)
    refilter(findNisByName)

    cities = _.sortBy cities, (city) -> city.name

    csv().from(cities).to('out/cities.csv', { columns: ['name', 'zipCode', 'nisCode', 'province', 'main'], header: true })

    console.log missing
    console.log missing.length
