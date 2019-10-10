
# USIGNormalizador

![Version](https://img.shields.io/cocoapods/v/USIGNormalizador.svg)
![Platform](https://img.shields.io/cocoapods/p/USIGNormalizador.svg)
[![Build Status](https://img.shields.io/travis/gcba/usig-normalizador-ios/master.svg)](https://travis-ci.org/gcba/usig-normalizador-ios)

Cliente iOS del [servicio de normalización de direcciones de USIG](http://servicios.usig.buenosaires.gob.ar/normalizar) para CABA y AMBA, desarrollado en Swift 4.

#### `Tener en cuenta`

  - Esta versión es compatible con ios 13 por lo que el proyecto que lo utilice debera compilar en swift 4

## Instalación


### Cocoapods

En el `Podfile` del proyecto:

```ruby
pod 'USIGNormalizador', '~> 2.0'
```


### Carthage

En el `Cartfile` del proyecto:

```
github "gcba/usig-normalizador-ios" ~> 2.0
```


## Métodos


### Búsqueda por calle

Devuelve un array de direcciones ordenadas por relevancia de acuerdo al término de búsqueda.

```swift
USIGNormalizador.search(query: <Nombre o parte del nombre de una calle>) { result, error in
    // Do something
}
```

#### Parámetros opcionales

##### excluding (String?)

Localidades a excluir de la búsqueda, separadas por coma. Por defecto se excluyen todas las localidades del AMBA (para obtener resultados sólo de CABA).

```swift
USIGNormalizador.search(query: "Callao", excluding: nil) { result, error in
    // Do something
}
```

##### maxResults (Int)

Cantidad máxima de resultados a devolver. Por defecto son 10.

```swift
USIGNormalizador.search(query: "Callao", maxResults: 7) { result, error in
    // Do something
}
```

##### includePlaces (Bool)

Incluir lugares en la búsqueda o no. Por defecto es `true`.

```swift
USIGNormalizador.search(query: "Callao", includePlaces: false) { result, error in
    // Do something
}
```

Los parámetros opcionales pueden ir juntos o separados.

```swift
USIGNormalizador.search(query: "Callao", excluding: nil, maxResults: 7, includePlaces: false) { result, error in
    // Do something
}
```


### Búsqueda por coordenadas

Devuelve la dirección más próxima a una latitud/longitud.

```swift
USIGNormalizador.location(latitude: <Una latitud>, longitude: <Una longitud>) { result, error in
    // Do something
}
```


## Interfaz

![Screenshot](https://raw.githubusercontent.com/gcba/usig-normalizador-ios/master/screenshot.png "Vista de búsqueda")

Permite buscar por el nombre de una calle o lugar. El controlador de la interfaz de búsqueda debe ser presentado por un `UINavigationController`.

```swift
let searchController = USIGNormalizador.searchController()
let navigationController = UINavigationController(rootViewController: searchController)

searchController.delegate = self

present(navigationController, animated: true)
```


### Editar

Es posible precargar un término de búsqueda antes de presentar el controlador.

```swift
searchController.edit = "CALLAO AV. 123"
```


### Modalidades

Hay dos modalidades opcionales, que pueden activarse juntas o separadas:

#### Mostrar pin

Agrega una celda en la parte superior de la tabla con la imagen de un [pin](https://www.google.com.ar/search?q=map+pin) y un texto configurable. Cuando se la tapea ejecuta el método `didSelectPin` del delegado. Se activa implementando el método `shouldShowPin` del delegado para que retorne `true`.

#### No forzar normalización

Da la posibilidad al usuario de escribir y elegir una calle que no esté entre los resultados de la búsqueda. Muestra una celda arriba de los resultados con el término de búsqueda ingresado, y cuando se la tapea pasa este valor al método `didSelectUnnormalizedAddress`. Se activa cuando el método `shouldForceNormalization` del delegado retorna `false`.


### Delegado

El controlador de búsqueda se configura implementando métodos del protocolo `USIGNormalizadorControllerDelegate`. Es obligatorio implementar `didSelectValue`; los demás métodos son opcionales.

#### shouldShowPin

Si se muestra la celda con el pin. El valor por defecto es `false`.

```swift
func shouldShowPin(_ searchController: USIGNormalizadorController) -> Bool {
    return true
}
```

#### shouldForceNormalization

Si se fuerza la normalización de las direcciones. El valor por defecto es `true`.

```swift
func shouldForceNormalization(_ searchController: USIGNormalizadorController) -> Bool {
    return false
}
```

#### shouldIncludePlaces

Si se incluyen lugares en la búsqueda. El valor por defecto es `true`.

```swift
func shouldIncludePlaces(_ searchController: USIGNormalizadorController) -> Bool {
    return false
}
```

#### shouldShowDetails

Si se muestran el partido y la localidad de cada dirección. El valor por defecto es `false`.

```swift
func shouldShowDetails(_ searchController: USIGNormalizadorController) -> Bool {
    return true
}
```

#### didSelectValue

Se ejecuta al tapear en uno de los resultados de la búsqueda.

```swift
func didSelectValue(_ searchController: USIGNormalizadorController, value: USIGNormalizadorAddress) {
    // Do something
}
```

#### didSelectUnnormalizedAddress

Cuando se selecciona la dirección custom escrita por el usuario.

```swift
func didSelectUnnormalizedAddress(_ searchController: USIGNormalizadorController, value: String) {
    // Do something
}
```

#### didSelectPin

Se ejecuta al tapear la celda del pin.

```swift
func didSelectPin(_ searchController: USIGNormalizadorController) {
    // Do something
}
```

#### didCancelSelection

Si se tapeó el botón **Cancelar**.

```swift
func didCancelSelection(_ searchController: USIGNormalizadorController) {
    // Do something
}
```

#### exclude

Localidades a excluir de la búsqueda, separadas por coma. El valor por defecto son las localidades del AMBA (para obtener resultados sólo de CABA).

```swift
func exclude(_ searchController: USIGNormalizadorController) -> String {
    return nil
}
```

#### maxResults

Cantidad máxima de resultados a devolver. Por defecto es 10.

```swift
func maxResults(_ searchController: USIGNormalizadorController) -> Int {
    return 7
}
```

#### pinImage

Permite cambiar el ícono del pin.

```swift
func pinImage(_ searchController: USIGNormalizadorController) -> UIImage! {
    return UIImage(named: "MyIcon")
}
```

#### pinColor

Color de tint que se aplicará al ícono del pin. El color por defecto es `UIColor.lightGray`.

```swift
func pinColor(_ searchController: USIGNormalizadorController) -> UIColor {
    return UIColor.black
}
```

#### pinText

El texto que aparecerá junto al pin. Por defecto es `"Fijar la ubicación en el mapa"`.

```swift
func pinText(_ searchController: USIGNormalizadorController) -> String {
    return "Marcar en el mapa"
}
```

#### addressImage

Permite cambiar el ícono de las direcciones.

```swift
func addressImage(_ searchController: USIGNormalizadorController) -> UIImage! {
    return UIImage(named: "MyIcon")
}
```

#### addressColor

Color de tint que se aplicará al ícono de las direcciones. El color por defecto es `UIColor.lightGray`.

```swift
func addressColor(_ searchController: USIGNormalizadorController) -> UIColor {
    return UIColor.black
}
```

#### placeImage

Permite cambiar el ícono de los lugares.

```swift
func placeImage(_ searchController: USIGNormalizadorController) -> UIImage! {
    return UIImage(named: "MyIcon")
}
```

#### placeColor

Color de tint que se aplicará al ícono de los lugares. El color por defecto es `UIColor.lightGray`.

```swift
func placeColor(_ searchController: USIGNormalizadorController) -> UIColor {
    return UIColor.black
}
```


### Localización

Para que el botón `Cancelar` aparezca en español, asegurarse que en el `Info.plist` de la **app** la clave `Localization native development region` tenga el valor `es`.


## API

`USIGNormalizador.api` expone un [Moya provider](https://github.com/Moya/Moya) para realizar llamadas directas al [servicio de normalización de direcciones de USIG](http://servicios.usig.buenosaires.gob.ar/normalizar).


## Licencia

    MIT License

    Copyright (c) 2017+ Buenos Aires City Government

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
