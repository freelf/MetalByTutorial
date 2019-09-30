import PlaygroundSupport
import MetalKit

guard let device = MTLCreateSystemDefaultDevice() else {
  fatalError("GPU is not supported")
}

let frame = CGRect(x: 0, y: 0, width: 600, height: 600)
let view = MTKView(frame: frame, device: device)
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)

// 加载顶点数据
struct Vertex {
    var position: simd_float4
}
let first = Vertex(position: [0.5, -0.5, 0, 1])
let second = Vertex(position: [-0.5, -0.5, 0, 1])
let third = Vertex(position: [0, 0.5, 0, 1])
let vertexs = [first, second, third]
// 创建command queue
guard let commandQueue = device.makeCommandQueue() else {
  fatalError("Could not create a command queue")
}
// 着色器函数
let shader = """
#include <metal_stdlib> \n
using namespace metal;

struct VertexIn {
  float4 position;
};

vertex float4 vertex_main(constant VertexIn *vertices [[buffer(0)]],
uint vid [[vertex_id]]) {
  return vertices[vid].position;
}

fragment float4 fragment_main() {
  return float4(1, 0, 0, 1);
}
"""
// 设置渲染管道
let library = try device.makeLibrary(source: shader, options: nil)
let vertexFunction = library.makeFunction(name: "vertex_main")
let fragmentFunction = library.makeFunction(name: "fragment_main")

let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

// 提交渲染指令
guard let commandBuffer = commandQueue.makeCommandBuffer(),
    
let descriptor = view.currentRenderPassDescriptor,
    
let renderEncoder =
  commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
  else { fatalError() }

renderEncoder.setRenderPipelineState(pipelineState)
renderEncoder.setVertexBytes(vertexs, length: MemoryLayout<Vertex>.size * 3, index: 0)

renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

renderEncoder.endEncoding()
guard let drawable = view.currentDrawable else {
  fatalError()
}
commandBuffer.present(drawable)
commandBuffer.commit()
// 显示渲染结果
PlaygroundPage.current.liveView = view
