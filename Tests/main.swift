import Foundation

runFuzzyMatcherTests()
runSearchNormalizationTests()
runPinyinMatchingTests()
runRankingEngineTests()
runActionRegistryTests()
runStateMachineTests()
runURLEncoderTests()
runFileSearchTests()
runApplicationIndexTests()
runApplicationLaunchMatrix()
runFileSearchIntegrationTests()

if TestSupport.failures == 0 {
    print("All tests passed.")
    exit(0)
} else {
    fputs("\(TestSupport.failures) test(s) failed.\n", stderr)
    exit(1)
}
