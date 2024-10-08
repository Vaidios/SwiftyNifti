import Foundation

final class NiftiV1BinaryReader: BinaryReader {
  
  var isByteSwapped: Bool = false
  let data: Data
  
  init(data: Data) {
    self.data = data
  }
  
  func getHeader() throws(NiftiV1Error) -> NiftiV1.Header {
    
    var hdr = NiftiV1.Header()
    
    //Checking endianess
    var sizeOfHdr: Int32 = readValue(at: 0)
    if sizeOfHdr != 348 {
      isByteSwapped = true
      sizeOfHdr = sizeOfHdr.byteSwapped
    }
    
    if sizeOfHdr != 348 {
      throw .invalidHeaderSize
    }
    
    hdr.sizeof_hdr = sizeOfHdr
    ///Byte offset - 39 dim_info
    hdr.dim_info = readValue(at: 39)
    ///Byte offset - 40 - dimensions
    hdr.dim = readVector(at: 40, length: 8)
    try updateDimsFromArray(dims: &hdr.dim)
    ///Byte offset - 56 - intent_p1
    hdr.intent_p1 = readValue(at: 58)
    ///Byte offset - 60 - intent_p2
    hdr.intent_p2 = readValue(at: 60)
    ///Byte offset - 64 - intent_p3
    hdr.intent_p3 = readValue(at: 64)
    
    ///Byte offset - 68 - Intent code
    hdr.intent_code = readValue(at: 68)
    //////Byte offset - 70 - Data type
    hdr.datatype = readValue(at: 70)
    ///Byte offset - 72 - Bit pix
    hdr.bitpix = readValue(at: 72)
    //////Byte offset - 74 - slice_start
    hdr.slice_start = readValue(at: 74)
    
    ///Byte offset - 76 - pixdim
    hdr.pixdim = readVector(at: 76, length: 8)
    
    ///Byte offset - 108 - vox_offset
    hdr.vox_offset = readValue(at: 108)
    
    ///Byte offset - 112 - scl_slope
    hdr.scl_slope = readValue(at: 112)
    ///Byte offset - 116 - scl_inter
    hdr.scl_inter = readValue(at: 116)
    ///Byte offset - 120 - slice_end
    hdr.slice_end = readValue(at: 120)
    ///Byte offset - 122 - slice_code
    hdr.slice_code = readValue(at: 122)
    
    ///Byte offset - 123 - xyzt_units
    hdr.xyzt_units = readValue(at: 123)
    
    ///Byte offset - 124 - cal_max
    hdr.cal_max = readValue(at: 124)
    ///Byte offset - 128 - cal_min
    hdr.cal_min = readValue(at: 128)
    
    ///Byte offset - 132 - slice_duration
    hdr.slice_duration = readValue(at: 132)
    ///Byte offset - 136 - toffset
    hdr.toffset = readValue(at: 136)
    
    ///Byte offset - 140 - glmax int
    hdr.glmax = readValue(at: 140)
    ///Byte offset - 144 - glmin int
    hdr.glmin = readValue(at: 144)
    
    ///Byte offset - 148 - description [UInt8]
    hdr.descript = readVector(at: 148, length: 80)
    ///Byte offset - 228 - aux_file [UInt8]
    hdr.aux_file = readVector(at: 228, length: 24)
    
    ///Byte offset - 252 - qform_code
    hdr.qform_code = readValue(at: 252)
    ///Byte offset - 254 - sform_code
    hdr.sform_code = readValue(at: 254)
    
    ///Byte offset - 256 - quatern_b
    hdr.quatern_b = readValue(at: 256)
    ///Byte offset - 260 - quatern_c
    hdr.quatern_c = readValue(at: 260)
    ///Byte offset - 264 - quatern_d
    hdr.quatern_d = readValue(at: 264)
    ///Byte offset - 268 - qoffset_x
    hdr.qoffset_x = readValue(at: 268)
    ///Byte offset - 272 - qoffset_y
    hdr.qoffset_y = readValue(at: 272)
    ///Byte offset - 276 - qoffset_z
    hdr.qoffset_z = readValue(at: 276)
    
    ///Byte offset - 280 - srow_x
    hdr.srow_x = readVector(at: 280, length: 4)
    ///Byte offset - 296 - srow_y
    hdr.srow_y = readVector(at: 296, length: 4)
    ///Byte offset - 312 - srow_z
    hdr.srow_z = readVector(at: 312, length: 4)
    
    ///Byte offset - 328 - intent_name
    hdr.intent_name = readVector(at: 328, length: 16)
    
    ///Byte offset - 344 - magic
    hdr.magic = readVector(at: 344, length: 4)
    
    return hdr
  }
  
  func updateDimsFromArray(dims: inout [Int16]) throws(NiftiV1Error) {
    guard !dims.isEmpty else { throw .invalidDimensions }
    if dims[0] < 1 || dims[0] > 7 {
      print("Invalid dimensions")
      for (idx, size) in dims.enumerated() { print("Dim \(idx) has size of \(size)") }
      throw .invalidDimensions
    }
    
    if dims[1] < 1 { dims[1] = 1 }
    if dims[0] < 2 || (dims[0] >= 2 && dims[2] < 1) { dims[2] = 1 }
    if dims[0] < 3 || (dims[0] >= 3 && dims[3] < 1) { dims[3] = 1 }
    if dims[0] < 4 || (dims[0] >= 4 && dims[4] < 1) { dims[4] = 1 }
    if dims[0] < 5 || (dims[0] >= 5 && dims[5] < 1) { dims[5] = 1 }
    if dims[0] < 6 || (dims[0] >= 6 && dims[6] < 1) { dims[6] = 1 }
    if dims[0] < 7 || (dims[0] >= 7 && dims[7] < 1) { dims[7] = 1 }
    
    var nDim = Int(dims[0])
    for _ in dims.reversed() {
      
      if nDim > 1 && (dims[nDim] <= 1) {
        nDim -= 1
      } else { break }
    }
    dims[0] = Int16(nDim)
  }
  
  func getVoxels(using header: NiftiV1.Header) throws -> [Voxel] {
    let dimensions = header.dimensions
    let voxelCount = dimensions.nx * dimensions.ny * dimensions.nz
    let voxelOffset = Int(header.vox_offset)
    let volumeData: Data
    if voxelCount < data.count / header.bytesPerVoxel {
      volumeData = data.subdata(in: voxelOffset ..< data.count)
    } else {
      volumeData = data
    }
    switch header.niftiDatatype {
    case .uint8:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt8) in Voxel(value: Float(value)) }
    case .uint16:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt16) in Voxel(value: Float(value)) }
    case .uint32:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt32) in Voxel(value: Float(value)) }
    case .float32:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: Float32) in
          let newValue = (value / Float32.greatestFiniteMagnitude) * 255
          return Voxel(value: Float(newValue))
        }
    default:
      throw NiftiV1Error.unsupportedDataFormat
    }
  }
  
  func getVoxels(using dimensions: VolumeDimensions, voxelOffset: Int, bytesPerVoxel: Int, datatype: DataType) throws -> [Voxel] {
    let voxelCount = dimensions.nx * dimensions.ny * dimensions.nz
    let volumeData: Data
    if voxelCount < data.count / bytesPerVoxel {
      volumeData = data.subdata(in: voxelOffset ..< data.count)
    } else {
      volumeData = data
    }
    switch datatype {
    case .uint8:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt8) in Voxel(value: Float(value)) }
    case .uint16:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt16) in Voxel(value: Float(value)) }
    case .uint32:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: UInt32) in Voxel(value: Float(value)) }
    case .float32:
      return volumeData.loadVector(length: voxelCount, isByteSwapped: isByteSwapped)
        .map { (value: Float32) in
          let newValue = (value / Float32.greatestFiniteMagnitude) * 255
          return Voxel(value: Float(newValue))
        }
    default:
      throw NiftiV1Error.unsupportedDataFormat
    }
  }
}
