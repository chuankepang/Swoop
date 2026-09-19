import Foundation

runFuzzyMatcherTests()
runRankingEngineTests()
runActionRegistryTests()
runStateMachineTests()
runURLEncoderTests()

if TestSupport.failures == 0 {
    print("All tests passed.")
    exit(0)
} else {
    fputs("\(TestSupport.failures) test(s) failed.\n", stderr)
    exit(1)
}
