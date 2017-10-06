# USIGNormalizador

Cliente iOS del [servicio de normalización de direcciones de USIG](http://servicios.usig.buenosaires.gob.ar/normalizar). Escrito en Swift 3.

## UI

![Screeshot](https://raw.githubusercontent.com/gcba/usig-normalizador-ios/master/screenshot.png "Vista de búsqueda")

El controlador de la interfaz de búsqueda debe ser presentado por un `UINavigationController`.

```swift
let searchController = USIGNormalizador.searchController()
let navigationController = UINavigationController(rootViewController: searchController)

searchController.delegate = self

present(navigationController, animated: true, completion: nil)
```

### Editar

Es posible precargar un término de búsqueda antes de presentar el controlador.

```swift
searchController.edit = "CALLAO AV. 123"
```

### Delegado

El controlador de búsqueda se configura implementando métodos del protocolo `USIGNormalizadorControllerDelegate`. Es obligatorio implementar `didSelectValue`; los demás métodos son opcionales.

#### shouldShowPin

```swift
func shouldShowPin(_ search: USIGNormalizadorController) -> Bool {
    return true
}
```

#### shouldForceNormalization

```swift
func shouldForceNormalization(_ search: USIGNormalizadorController) -> Bool {
    return forceNormalization
}
```

#### didSelectValue

```swift
func didSelectValue(_ search: USIGNormalizadorController, value: USIGNormalizadorAddress) {
    // Do something
}
```

#### didSelectPin

```swift
func didSelectPin(_ search: USIGNormalizadorController) {
    // Do something
}
```

#### didSelectUnnormalizedAddress

```swift
func didSelectUnnormalizedAddress(_ search: USIGNormalizadorController, value: String) {
    // Do something
}
```

#### exclude

```swift
func exclude(_ search: USIGNormalizadorController) -> String { return
    USIGNormalizadorExclusions.GBA.rawValue
}
```

#### maxResults

```swift
func maxResults(_ search: USIGNormalizadorController) -> Int {
    return 10
}
```

#### pinColor

```swift
func pinColor(_ search: USIGNormalizadorController) -> UIColor {
    return UIColor.darkGray
}
```

#### pinImage

```swift
func pinImage(_ search: USIGNormalizadorController) -> UIImage! {
    return UIImage(named: "MyPin")
}
```

#### pinText

```swift
func pinText(_ search: USIGNormalizadorController) -> String {
    return "Fijar la ubicación en el mapa"
}
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

Localidades a excluir de la búsqueda, separadas por coma. Por defecto se excluyen todas las localidades que no pertenecen a la CABA (para buscar sólo entre las calles de la Ciudad).

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

Los parámetros opcionales pueden ir juntos o separados.

```swift
USIGNormalizador.search(query: "Callao", excluding: nil, maxResults: 7) { result, error in
	// Do something
}
```

### Búsqueda por coordenadas

Devuelve la dirección de la esquina más próxima a una latitud/longitud.

```swift
USIGNormalizador.location(latitude: <Una latitud>, longitude: <Una longitud>) { result, error in
	// Do something
}
```

## API

`USIGNormalizador.api` expone un [Moya provider](https://github.com/Moya/Moya) para realizar llamadas directas al [servicio de normalización de direcciones de USIG](http://servicios.usig.buenosaires.gob.ar/normalizar).