<script setup lang="ts">
import { useUploadState } from './useUploadState'

const { isMobileMode } = useGlobal()

const { tempFiles, addFiles, clearFiles, closeModal, isLoading } = useUploadState()

const videoStream = ref<MediaStream | null>(null)
const permissionGranted = ref(false)
const facingMode = ref<'user' | 'environment'>('environment')
const hasMultipleCameras = ref(false)

const capturedImage = computed(() => tempFiles.value[0] || null)
const videoRef = ref<HTMLVideoElement | undefined>()
const canvasRef = ref<HTMLCanvasElement | undefined>()

const checkMultipleCameras = async () => {
  try {
    const devices = await navigator.mediaDevices.enumerateDevices()
    const videoDevices = devices.filter((d) => d.kind === 'videoinput')
    hasMultipleCameras.value = videoDevices.length > 1
  } catch {
    hasMultipleCameras.value = false
  }
}

const startCamera = async () => {
  try {
    // Stop any existing stream before starting a new one
    if (videoStream.value) {
      for (const track of videoStream.value.getTracks()) {
        track.stop()
      }
      videoStream.value = null
    }

    videoStream.value = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: facingMode.value },
    })
    permissionGranted.value = true

    await checkMultipleCameras()

    // Wait for next tick to ensure video element is rendered
    await nextTick()

    if (!videoRef.value || !videoStream.value) return
    videoRef.value.srcObject = videoStream.value

    try {
      await videoRef.value.play()
    } catch (playError) {
      console.error('Error playing video:', playError)
    }
  } catch (error) {
    console.error('Camera access denied:', error)
  }
}

const switchCamera = () => {
  facingMode.value = facingMode.value === 'user' ? 'environment' : 'user'
  startCamera()
}

const stopCamera = () => {
  if (videoStream.value) {
    for (const track of videoStream.value.getTracks()) {
      track.stop()
    }
  }
  videoStream.value = null

  if (videoRef.value) {
    videoRef.value.srcObject = null
  }
}

const captureImage = () => {
  const video = videoRef.value
  const canvas = canvasRef.value

  if (!video || !canvas) return

  canvas.width = video.videoWidth
  canvas.height = video.videoHeight
  const context = canvas.getContext('2d')

  if (context) {
    canvas.style.display = 'block'
    if (facingMode.value === 'user') {
      context.translate(canvas.width, 0)
      context.scale(-1, 1)
    }
    context.drawImage(video, 0, 0, canvas.width, canvas.height)
    canvas.toBlob((blob) => {
      if (!blob) return
      const file = new File([blob], `${new Date().toDateString()}.png`, { type: 'image/png' })
      addFiles([file])
    }, 'image/png')
    stopCamera()
  }
}

const retakeImage = () => {
  clearFiles()
  startCamera()
}

onMounted(() => {
  startCamera()
})

onBeforeUnmount(() => {
  stopCamera()
})
</script>

<template>
  <div class="w-full relative h-full">
    <NcTooltip class="absolute top-3 right-2 z-10">
      <NcButton type="text" class="!border-0" :disabled="isLoading" :size="isMobileMode ? 'small' : 'xsmall'" @click="closeModal">
        <GeneralIcon icon="close" />
      </NcButton>

      <template #title> {{ $t('general.close') }} </template>
    </NcTooltip>
    <div v-if="!permissionGranted" class="w-full h-full flex bg-nc-bg-gray-extralight items-center justify-center">
      <div
        class="flex flex-col hover:bg-nc-bg-default p-2 cursor-pointer rounded-md !transition-all transition-ease-in-out duration-300 gap-2 items-center justify-center"
        @click="startCamera"
      >
        <div class="p-5 bg-nc-bg-default rounded-md shadow-sm">
          <mdi-camera class="text-4xl text-nc-content-gray" />
        </div>
        <h1 class="text-nc-content-gray font-semibold text-center text-xl">
          {{ $t('labels.allowAccessToYourCamera') }}
        </h1>
      </div>
    </div>
    <div
      v-else
      :class="{
        'py-8': !capturedImage,
        'pt-8 pb-2': capturedImage,
      }"
      class="w-full gap-3 h-full flex-col flex items-center justify-between"
    >
      <div v-show="!capturedImage" class="w-full gap-3 h-full flex-col flex items-center justify-between">
        <video
          ref="videoRef"
          class="rounded-md w-full aspect-video max-w-md flex-1 object-contain"
          :style="{ transform: facingMode === 'user' ? 'scaleX(-1)' : 'none' }"
          autoplay
          playsinline
        ></video>

        <div class="flex items-center gap-3">
          <NcButton class="!rounded-full !px-0" :disabled="isLoading" @click="captureImage">
            <mdi-camera class="text-xl" />
          </NcButton>

          <NcTooltip v-if="hasMultipleCameras">
            <NcButton type="secondary" class="!rounded-full !px-0" :disabled="isLoading" size="small" @click="switchCamera">
              <GeneralIcon icon="refresh" />
            </NcButton>
            <template #title> {{ $t('labels.switchCamera') }} </template>
          </NcTooltip>
        </div>
      </div>

      <div v-show="capturedImage" class="flex group flex-col">
        <canvas ref="canvasRef" class="mb-2 rounded-md w-full aspect-video max-w-md flex-1 object-contain"></canvas>

        <div class="relative text-[12px] font-semibold text-nc-content-gray flex">
          <div class="flex-auto truncate line-height-4">
            {{ capturedImage?.name }}
          </div>
          <div
            v-if="!isLoading"
            class="flex-none hide-ui transition-all transition-ease-in-out !h-4 flex items-center bg-nc-bg-default"
          >
            <NcTooltip placement="bottom">
              <template #title> {{ $t('title.removeFile') }} </template>
              <GeneralIcon icon="delete" class="!text-nc-content-red-medium cursor-pointer" @click="retakeImage" />
            </NcTooltip>
          </div>
        </div>
        <div class="flex-none text-[10px] font-semibold text-nc-content-gray-muted">
          {{ formatBytes(capturedImage?.size, 0) }}
        </div>
      </div>
      <NcFileUploadProvidersBottomBar v-show="capturedImage" class="pr-2 bottom-1 relative" upload-text="Upload Image" />
    </div>
  </div>
</template>
