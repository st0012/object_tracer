# Changelog

## [v0.6.1](https://github.com/st0012/tapping_device/tree/v0.6.1) (2021-05-09)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.6.0...v0.6.1)

**Fixed bugs:**

- Fix issues with pastel [\#78](https://github.com/st0012/tapping_device/pull/78) ([st0012](https://github.com/st0012))

**Merged pull requests:**

- Drop activesupport [\#77](https://github.com/st0012/tapping_device/pull/77) ([st0012](https://github.com/st0012))
- Implement Configuration class manually [\#76](https://github.com/st0012/tapping_device/pull/76) ([st0012](https://github.com/st0012))
- Clean gemspec [\#75](https://github.com/st0012/tapping_device/pull/75) ([st0012](https://github.com/st0012))
- Replace pry with method_source [\#74](https://github.com/st0012/tapping_device/pull/74) ([st0012](https://github.com/st0012))

## [v0.6.0](https://github.com/st0012/tapping_device/tree/v0.6.0) (2021-04-25)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.7...v0.6.0)

**Implemented enhancements:**

- Support Ruby 3.0 [\#71](https://github.com/st0012/tapping_device/pull/71) ([st0012](https://github.com/st0012))

**Merged pull requests:**

- Drop activerecord requirement [\#73](https://github.com/st0012/tapping_device/pull/73) ([st0012](https://github.com/st0012))
- Improve file-writing tests [\#72](https://github.com/st0012/tapping_device/pull/72) ([st0012](https://github.com/st0012))
- Simplify output logic with Ruby' Logger class [\#70](https://github.com/st0012/tapping_device/pull/70) ([st0012](https://github.com/st0012))
- Refactor Payload classes [\#68](https://github.com/st0012/tapping_device/pull/68) ([st0012](https://github.com/st0012))

## [v0.5.7](https://github.com/st0012/tapping_device/tree/v0.5.7) (2020-09-09)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.6...v0.5.7)

**Implemented enhancements:**

- Use pastel in output payload [\#62](https://github.com/st0012/tapping_device/issues/62)

**Closed issues:**

- Support tag option [\#64](https://github.com/st0012/tapping_device/issues/64)

**Merged pull requests:**

- Use pastel to replace handmade colorizing logic [\#66](https://github.com/st0012/tapping_device/pull/66) ([st0012](https://github.com/st0012))
- Add tag option [\#65](https://github.com/st0012/tapping_device/pull/65) ([st0012](https://github.com/st0012))

## [v0.5.6](https://github.com/st0012/tapping_device/tree/v0.5.6) (2020-07-17)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.5...v0.5.6)

## [v0.5.5](https://github.com/st0012/tapping_device/tree/v0.5.5) (2020-07-16)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.4...v0.5.5)

**Fixed bugs:**

- InitializationTracker's logic can cause error [\#60](https://github.com/st0012/tapping_device/issues/60)

**Closed issues:**

- Refactor get\_method\_from\_object [\#59](https://github.com/st0012/tapping_device/issues/59)

**Merged pull requests:**

- Fix init tracker [\#61](https://github.com/st0012/tapping_device/pull/61) ([st0012](https://github.com/st0012))

## [v0.5.4](https://github.com/st0012/tapping_device/tree/v0.5.4) (2020-07-05)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.3...v0.5.4)

**Closed issues:**

- Add with\_print\_calls method [\#52](https://github.com/st0012/tapping_device/issues/52)
- Tapping any instance of class [\#51](https://github.com/st0012/tapping_device/issues/51)
- Add ignore\_private option [\#50](https://github.com/st0012/tapping_device/issues/50)

**Merged pull requests:**

- Restructure README.md [\#58](https://github.com/st0012/tapping_device/pull/58) ([st0012](https://github.com/st0012))
- Better support on private methods [\#57](https://github.com/st0012/tapping_device/pull/57) ([st0012](https://github.com/st0012))
- Add with\_\* helpers \(e.g. with\_print\_calls\) [\#56](https://github.com/st0012/tapping_device/pull/56) ([st0012](https://github.com/st0012))
- Add force\_recording option for debugging [\#55](https://github.com/st0012/tapping_device/pull/55) ([st0012](https://github.com/st0012))
- Add print\_instance\_\* and write\_instance\_\* helpers [\#54](https://github.com/st0012/tapping_device/pull/54) ([st0012](https://github.com/st0012))
- Fix tap\_init by adding c\_\* event type [\#53](https://github.com/st0012/tapping_device/pull/53) ([st0012](https://github.com/st0012))

## [v0.5.3](https://github.com/st0012/tapping_device/tree/v0.5.3) (2020-06-21)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.2...v0.5.3)

**Closed issues:**

- Global Configuration [\#46](https://github.com/st0012/tapping_device/issues/46)
- Support write\_\* helpers [\#44](https://github.com/st0012/tapping_device/issues/44)
- Use Method\#source to replace Payload\#method\_head’s implementation  [\#19](https://github.com/st0012/tapping_device/issues/19)

**Merged pull requests:**

- Support Global Configuration [\#48](https://github.com/st0012/tapping_device/pull/48) ([st0012](https://github.com/st0012))
- Support write\_\* helpers [\#47](https://github.com/st0012/tapping_device/pull/47) ([st0012](https://github.com/st0012))
- Hijack attr methods with `hijack\_attr\_methods` option [\#45](https://github.com/st0012/tapping_device/pull/45) ([st0012](https://github.com/st0012))

## [v0.5.2](https://github.com/st0012/tapping_device/tree/v0.5.2) (2020-06-10)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.1...v0.5.2)

**Closed issues:**

- Add print\_mutations [\#41](https://github.com/st0012/tapping_device/issues/41)
- Add tap\_on\_mutation! [\#18](https://github.com/st0012/tapping_device/issues/18)

**Merged pull requests:**

- Print mutations [\#43](https://github.com/st0012/tapping_device/pull/43) ([st0012](https://github.com/st0012))
- Refactorings [\#42](https://github.com/st0012/tapping_device/pull/42) ([st0012](https://github.com/st0012))

## [v0.5.1](https://github.com/st0012/tapping_device/tree/v0.5.1) (2020-06-07)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.5.0...v0.5.1)

**Fixed bugs:**

- Filter Out Entries From TappingDevice [\#35](https://github.com/st0012/tapping_device/issues/35)

**Merged pull requests:**

- Update GitHub Actions Configuration [\#40](https://github.com/st0012/tapping_device/pull/40) ([st0012](https://github.com/st0012))
- Fix typo: Guadian -\> Guardian [\#39](https://github.com/st0012/tapping_device/pull/39) ([skade](https://github.com/skade))
- Filter out calls about TappingDevice [\#38](https://github.com/st0012/tapping_device/pull/38) ([st0012](https://github.com/st0012))
- Drop tap\_sql! [\#37](https://github.com/st0012/tapping_device/pull/37) ([st0012](https://github.com/st0012))
- Add CollectionProxy class [\#36](https://github.com/st0012/tapping_device/pull/36) ([st0012](https://github.com/st0012))

## [v0.5.0](https://github.com/st0012/tapping_device/tree/v0.5.0) (2020-05-25)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.11...v0.5.0)

**Closed issues:**

- Colorize output of tracing helpers [\#25](https://github.com/st0012/tapping_device/issues/25)

**Merged pull requests:**

- Update README.md [\#34](https://github.com/st0012/tapping_device/pull/34) ([st0012](https://github.com/st0012))
- Colorize output [\#33](https://github.com/st0012/tapping_device/pull/33) ([st0012](https://github.com/st0012))
- Add TappingDevice\#with to register a with condition [\#32](https://github.com/st0012/tapping_device/pull/32) ([st0012](https://github.com/st0012))

## [v0.4.11](https://github.com/st0012/tapping_device/tree/v0.4.11) (2020-04-19)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.10...v0.4.11)

**Merged pull requests:**

- Update rake requirement from ~\> 10.0 to ~\> 13.0 [\#31](https://github.com/st0012/tapping_device/pull/31) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v0.4.10](https://github.com/st0012/tapping_device/tree/v0.4.10) (2020-02-05)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.9...v0.4.10)

**Implemented enhancements:**

- Usability improvements [\#30](https://github.com/st0012/tapping_device/pull/30) ([st0012](https://github.com/st0012))

**Merged pull requests:**

- Fix tap\_init!'s payload content [\#29](https://github.com/st0012/tapping_device/pull/29) ([st0012](https://github.com/st0012))
- Refactorings and fixes [\#28](https://github.com/st0012/tapping_device/pull/28) ([st0012](https://github.com/st0012))

## [v0.4.9](https://github.com/st0012/tapping_device/tree/v0.4.9) (2020-01-20)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.8...v0.4.9)

**Implemented enhancements:**

- Improve detail\_call\_info's output format [\#27](https://github.com/st0012/tapping_device/pull/27) ([st0012](https://github.com/st0012))

## [v0.4.8](https://github.com/st0012/tapping_device/tree/v0.4.8) (2020-01-05)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.7...v0.4.8)

**Closed issues:**

- Provide options for tapping on call or return events [\#23](https://github.com/st0012/tapping_device/issues/23)

**Merged pull requests:**

- Add tracing helpers [\#24](https://github.com/st0012/tapping_device/pull/24) ([st0012](https://github.com/st0012))

## [v0.4.7](https://github.com/st0012/tapping_device/tree/v0.4.7) (2019-12-29)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.6...v0.4.7)

**Implemented enhancements:**

- Config test coverage for codeclimate [\#22](https://github.com/st0012/tapping_device/pull/22) ([st0012](https://github.com/st0012))

**Closed issues:**

- Support tracking ActiveRecord::Base instances by their ids [\#17](https://github.com/st0012/tapping_device/issues/17)

**Merged pull requests:**

- Refactor tests and some minor fixes [\#21](https://github.com/st0012/tapping_device/pull/21) ([st0012](https://github.com/st0012))
- Support track\_as\_records option [\#20](https://github.com/st0012/tapping_device/pull/20) ([st0012](https://github.com/st0012))

## [v0.4.6](https://github.com/st0012/tapping_device/tree/v0.4.6) (2019-12-25)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.5...v0.4.6)

**Merged pull requests:**

- Add TappingDevice\#and\_print method [\#16](https://github.com/st0012/tapping_device/pull/16) ([st0012](https://github.com/st0012))
- Add Payload\#detail\_call\_info and improve method\_name's format [\#15](https://github.com/st0012/tapping_device/pull/15) ([st0012](https://github.com/st0012))

## [v0.4.5](https://github.com/st0012/tapping_device/tree/v0.4.5) (2019-12-15)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.4...v0.4.5)

## [v0.4.4](https://github.com/st0012/tapping_device/tree/v0.4.4) (2019-12-15)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.3...v0.4.4)

**Merged pull requests:**

- Implement tap\_passed! [\#14](https://github.com/st0012/tapping_device/pull/14) ([st0012](https://github.com/st0012))

## [v0.4.3](https://github.com/st0012/tapping_device/tree/v0.4.3) (2019-12-09)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.2...v0.4.3)

## [v0.4.2](https://github.com/st0012/tapping_device/tree/v0.4.2) (2019-12-09)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.1...v0.4.2)

**Merged pull requests:**

- Refactor tap\_sql! [\#13](https://github.com/st0012/tapping_device/pull/13) ([st0012](https://github.com/st0012))
- Improve tap sql [\#12](https://github.com/st0012/tapping_device/pull/12) ([st0012](https://github.com/st0012))

## [v0.4.1](https://github.com/st0012/tapping_device/tree/v0.4.1) (2019-12-06)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.4.0...v0.4.1)

**Merged pull requests:**

- Add TappingDevice::Payload class [\#11](https://github.com/st0012/tapping_device/pull/11) ([st0012](https://github.com/st0012))

## [v0.4.0](https://github.com/st0012/tapping_device/tree/v0.4.0) (2019-11-25)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- Support tap\_sql! [\#10](https://github.com/st0012/tapping_device/pull/10) ([st0012](https://github.com/st0012))
- Minor adjustment [\#9](https://github.com/st0012/tapping_device/pull/9) ([NickWarm](https://github.com/NickWarm))

## [v0.3.0](https://github.com/st0012/tapping_device/tree/v0.3.0) (2019-11-03)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.2.0...v0.3.0)

**Implemented enhancements:**

- Largely improve performance by fixing bad design [\#8](https://github.com/st0012/tapping_device/pull/8) ([st0012](https://github.com/st0012))

## [v0.2.0](https://github.com/st0012/tapping_device/tree/v0.2.0) (2019-11-02)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.1.1...v0.2.0)

**Implemented enhancements:**

- Add Device class [\#3](https://github.com/st0012/tapping_device/pull/3) ([st0012](https://github.com/st0012))

**Merged pull requests:**

- Remove tapping\_deivce/device.rb [\#7](https://github.com/st0012/tapping_device/pull/7) ([st0012](https://github.com/st0012))
- Reduce namespace [\#6](https://github.com/st0012/tapping_device/pull/6) ([st0012](https://github.com/st0012))
- Register and control all devices from Device class [\#5](https://github.com/st0012/tapping_device/pull/5) ([st0012](https://github.com/st0012))
- Support `TappingDevice::Device\#stop\_when` [\#4](https://github.com/st0012/tapping_device/pull/4) ([st0012](https://github.com/st0012))

## [v0.1.1](https://github.com/st0012/tapping_device/tree/v0.1.1) (2019-10-20)

[Full Changelog](https://github.com/st0012/tapping_device/compare/v0.1.0...v0.1.1)

**Implemented enhancements:**

- More filters, Refactoring and Readme update [\#2](https://github.com/st0012/tapping_device/pull/2) ([st0012](https://github.com/st0012))
- Support tapping ActiveRecord class/instance [\#1](https://github.com/st0012/tapping_device/pull/1) ([st0012](https://github.com/st0012))

## [v0.1.0](https://github.com/st0012/tapping_device/tree/v0.1.0) (2019-10-19)

[Full Changelog](https://github.com/st0012/tapping_device/compare/61039c87a55c664661b788e24311e263b28a3ee8...v0.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
