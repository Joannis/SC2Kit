import Foundation

let protocolFiles = try FileManager.default.contentsOfDirectory(atPath: "./s2client-proto/s2clientprotocol/")

for file in protocolFiles where file.hasSuffix(".proto") && !file.contains("commmon") {
    let process = Process()
    process.launchPath = "/usr/local/bin/protoc"
    process
    process.arguments = [
        "--swift_out=\(process.currentDirectoryPath)/Sources/SC2Kit/",
        "--proto_path=\(process.currentDirectoryPath)/s2client-proto/",
        "s2clientprotocol/\(file)"
    ]
    process.launch()
    process.waitUntilExit()
}
