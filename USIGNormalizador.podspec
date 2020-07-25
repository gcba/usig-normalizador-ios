Pod::Spec.new do |spec|
    spec.name = 'USIGNormalizador'
    spec.version = '2.1.0'
    spec.summary = 'Cliente iOS del normalizador de direcciones de USIG'
    spec.homepage = 'https://github.com/gcba/usig-normalizador-ios'

    spec.authors = { 'Rita Zerrizuela' => 'zeta@widcket.com' }
    spec.license = { :type => 'MIT' }

    spec.ios.deployment_target = '12.2'

    spec.source = { :git => 'https://github.com/gcba/usig-normalizador-ios.git', :tag => "v#{spec.version}" }
    spec.source_files = 'USIGNormalizador/*.{swift}'
    spec.resources = ['USIGNormalizador/USIGNormalizador.storyboard', 'USIGNormalizadorResources/Assets.xcassets']

    spec.frameworks = 'Foundation', 'UIKit'
    spec.dependency 'RxCocoa', '~> 5'
    spec.dependency 'RxSwift', '~> 5'
    spec.dependency 'Moya/RxSwift', '~> 14.0'
    spec.dependency 'Result'
    spec.dependency 'DZNEmptyDataSet', '~> 1.8'
end