//
//  AudioTap.swift
//  AIDJ
//
//  Created by Akihiro Aida on 2017/04/05.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import AVFoundation

class AudioTap {
    var supportedTapProcessingFormat = true
    var isNonInterleaved = false
    var sampleRate: Double? = nil
    var sampleCount = 0.0
    var leftChannelVolume = 0.0
    var rightChannelVolume = 0.0
    
    init(playerItem: AVPlayerItem) {
        
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        
        print("err: \(err)\n")
        if err == noErr {
        }
        
        print("tracks? \(playerItem.asset.tracks)\n")
        
        let audioTrack = playerItem.asset.tracks(withMediaType: AVMediaTypeAudio).first!
        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
        inputParams.audioTapProcessor = tap?.takeUnretainedValue()
        
        // print("inputParms: \(inputParams), \(inputParams.audioTapProcessor)\n")
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [inputParams]
        
        playerItem.audioMix = audioMix
    }
    
    let tapInit: MTAudioProcessingTapInitCallback = {
        (tap: MTAudioProcessingTap, clientInfo: UnsafeMutableRawPointer?, tapStorageOut: UnsafeMutablePointer<UnsafeMutableRawPointer?>) in
        
        var nonOptionalSelf: AudioTap = clientInfo!.assumingMemoryBound(to: AudioTap.self).pointee
        
        var client = clientInfo
        print("init \(tap, clientInfo, tapStorageOut, nonOptionalSelf)\n")
        withUnsafeMutablePointer(to: &client){
            p in
            print("init, assign \(p)")
            tapStorageOut.assign(from: p, count: 1)
        }
    }
    
    let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
        (tap) in
        print("finalize \(tap)\n")
    }
    
    let tapPrepare: MTAudioProcessingTapPrepareCallback = {
        (tap, maxFrames: CMItemCount, processingFormat: UnsafePointer<AudioStreamBasicDescription>) in
        print("prepare: \(tap, maxFrames, processingFormat)")
        //        let a = MTAudioProcessingTapGetStorage(tap)
        //        print("prepare: \(a, type(of: a))")
        //        let b = a.assumingMemoryBound(to: AudioTap.self)
        //        print("prepare: \(b, type(of: b))")
        //
        //        var c = b.pointee
        //        print("prepare: \(c)")
        //        print("prepare: \(c, type(of: c))")
        //        let `self` = MTAudioProcessingTapGetStorage(tap).assumingMemoryBound(to: AudioTap.self).pointee
        //        print("prepare: \(c)")
        
        // Store sample rate for -setCenterFrequency:.
        var sampleRate = processingFormat.pointee.mSampleRate
        
        /* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
        var supportedTapProcessingFormat = true;
        var isNonInterleaved = false
        
        if (processingFormat.pointee.mFormatID != kAudioFormatLinearPCM) {
            NSLog("Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
            supportedTapProcessingFormat = false;
        }
        
        if (processingFormat.pointee.mFormatFlags & kAudioFormatFlagIsFloat) == 0 {
            NSLog("Unsupported audio format flag for audioProcessingTap. Float only.");
            supportedTapProcessingFormat = false;
        }
        
        if (processingFormat.pointee.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0 {
            isNonInterleaved = true;
        }
        print("prepare: \(sampleRate, supportedTapProcessingFormat, isNonInterleaved)")
    }
    
    let tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
        (tap) in
        print("unprepare \(tap)\n")
    }
    
    let tapProcess: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        //        print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
        
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        //        print("get audio: \(status)\n")
        // Skip processing when format not supported.
        //        if (!supportedTapProcessingFormat) {
        //            NSLog("Unsupported tap processing format.");
        //            return;
        //        }
        AudioTap.calcVolume(numberFrames: numberFrames, bufferList: bufferListInOut.pointee)
    }
    
    static func calcVolume(numberFrames: CMItemCount, bufferList: AudioBufferList){
        // Calculate root mean square (RMS) for left and right audio channel.
        //        let bufferSize = Int(bufferList.mNumberBuffers)
        //        let buffers: (AudioBuffer)  = bufferList.mBuffers
        let samples = numberFrames
        //        NSLog("calcVolume \(bufferSize, buffers, samples)")
        
        if let dataa = bufferList.mBuffers.mData {
            let data = dataa.assumingMemoryBound(to: Float.self).pointee
            var rms: Float = 0.0
            for _ in 0..<samples {
                rms += data * data
            }
            
            if (samples > 0) {
                rms = sqrtf(rms / Float(samples))
            }
            print("calcVolume: vol \(rms)")
        }
    }
    
    static func setAudioTap(playerItem: AVPlayerItem) {
//        if let _ = playerItem!.asset.tracks as? [AVAssetTrack] {
//        }
        _ = AudioTap(playerItem: playerItem)
    }
}
