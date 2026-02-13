<script setup lang="ts">
const { $api } = useNuxtApp()

const { currentVersion, latestRelease, hiddenRelease, appInfo } = useGlobal()

const releaseAlert = computed({
  get() {
    if (currentVersion.value?.includes('-beta.') || latestRelease.value?.includes('-beta.')) {
      return false
    }
    return (
      currentVersion.value &&
      latestRelease.value &&
      currentVersion.value !== latestRelease.value &&
      latestRelease.value !== hiddenRelease.value
    )
  },
  set(val) {
    hiddenRelease.value = val ? null : latestRelease.value
  },
})

async function fetchReleaseInfo() {
  try {
    const versionInfo = await $api.utils.appVersion()
    if (versionInfo && versionInfo.releaseVersion && versionInfo.currentVersion) {
      currentVersion.value = versionInfo.currentVersion
      latestRelease.value = versionInfo.releaseVersion
    } else {
      currentVersion.value = null
      latestRelease.value = null
    }
  } catch (e: any) {
    message.error(await extractSdkResponseErrorMsg(e))
  }
}

onMounted(async () => await fetchReleaseInfo())
</script>

<template>
  <div v-if="releaseAlert && !appInfo.ee" class="flex items-center">
    <a-dropdown :trigger="['click']" placement="bottom" overlay-class-name="nc-dropdown-upgrade-menu">
      <NcButton class="!bg-primary !border-none !mr-3" size="small">
        <div class="flex gap-1 items-center text-white">
          <span class="text-sm font-weight-medium">{{ $t('activity.upgrade.available') }}</span>
          <mdi-menu-down />
        </div>
      </NcButton>

      <template #overlay>
        <div class="mt-1 bg-nc-bg-default shadow-lg !border">
          <div class="nc-menu-item" @click="releaseAlert = false">
            <mdi-close />
            <!-- Hide menu -->
            {{ $t('general.hideMenu') }}
          </div>
        </div>
      </template>
    </a-dropdown>
  </div>
</template>
