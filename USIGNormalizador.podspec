Pod::Spec.new do |spec|
    spec.name = 'USIGNormalizador'
    spec.version = '2.0.0'
    spec.summary = 'Cliente iOS del normalizador de direcciones de USIG'
    spec.homepage = 'https://github.com/gcba/usig-normalizador-ios'

    spec.authors = { 'Rita Zerrizuela' => 'zeta@widcket.com' }
    spec.license = { :type => 'MIT' }

    spec.ios.deployment_target = '9.0'

    spec.source = { :git => 'https://github.com/gcba/usig-normalizador-ios.git', :tag => "v#{spec.version}" }
    spec.source_files = 'USIGNormalizador/*.{swift}'
    spec.resources = ['USIGNormalizador/USIGNormalizador.storyboard', 'USIGNormalizadorResources/Assets.xcassets']

    spec.frameworks = 'Foundation', 'UIKit'
    spec.dependency 'RxCocoa', '~> 4.1'
    spec.dependency 'Moya/RxSwift', '~> 10.0'
    spec.dependency 'DZNEmptyDataSet', '~> 1.8'
end