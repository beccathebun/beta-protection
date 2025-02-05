<template>
    <n-card title="Placeholder Management" size="small">
        <div>
            <n-tooltip trigger="hover">
                <template #trigger>
                    <n-button @click="openDir">Import Folder...</n-button>
                </template>
                Choose a folder with placeholders for a single category.
            </n-tooltip>
            <n-tooltip trigger="hover">
                <template #trigger>
                    <n-button @click="openFile">Import Single File...</n-button>
                </template>
                Choose a single image to use for any category.
            </n-tooltip>
        </div>
        <n-card
            v-if="newFiles && newFiles.length > 0"
            title="Importing Files"
            size="small"
            :style="{ maxHeight: '200px' }"
        >
            <n-grid x-gap="12" :cols="2">
                <n-gi>
                    <n-thing title="Category:">
                        <n-auto-complete
                            :input-props="{
                                autocomplete: 'disabled'
                            }"
                            :options="categoryOptions"
                            v-model:value="categoryName"
                            placeholder="Category Name"
                        />
                        <template #footer>
                            <n-button
                                @click="importCurrent"
                                :disabled="!categoryName"
                                primary
                            >Import</n-button>
                            <n-button @click="cancelImport" ghost>Cancel</n-button>
                        </template>
                    </n-thing>
                </n-gi>
                <n-gi>
                    <!-- CSS is hard so the list can wait -->
                    <!-- <n-list bordered>
                <n-list-item v-for="file in newFiles" v-bind:key="file.handle.name">
                    <n-thing :title="file.handle.name" :description="humanFileSize(file.file.size)" />
                </n-list-item>
                    </n-list>-->
                    <n-thing :title="importMsg" :description="humanFileSize(allFileSize)">
                        <template
                            #footer
                        >These files will be imported to the '{{ categoryName }}' category.</template>
                    </n-thing>
                </n-gi>
            </n-grid>
        </n-card>
        <template #footer>
            Beta Protection stores the placeholders in your browser's storage, so you can move/delete the imported files afterwards.
        </template>
    </n-card>
</template>
<script setup lang="ts">
import { LocalPlaceholder } from '@/placeholders';
import { IExtensionPreferences } from '@/preferences';
import { FileSystemClient } from '@/services';
import { PlaceholderService } from '@/services/placeholder-service';
import { dbg, humanFileSize } from "@/util";
import { services, updateUserPrefs, useEventEmitter, watchForChanges } from '@silveredgold/beta-shared-components';
import type { LoadedFileHandle } from "@silveredgold/beta-shared-components/lib/services";
import { NAutoComplete, NButton, NCard, NGi, NGrid, NThing, NTooltip, useNotification } from "naive-ui";
import { Ref, computed, inject, onBeforeMount, ref, toRefs, watch } from 'vue';

const props = defineProps<{
    preferences: IExtensionPreferences
}>();

const emitter = useEventEmitter();
const notif = useNotification();
const { preferences } = toRefs(props);
const prefs = preferences;
const updatePrefs = inject(updateUserPrefs);

const placeholders: Ref<LocalPlaceholder[]> = ref([]);
const newFiles: Ref<LoadedFileHandle[]> = ref([]);
const categoryName = ref('');

const categories = computed(() => [...new Set(placeholders.value.map(pl => pl.category))]);
const categoryOptions = computed(() => categories.value.filter(cat => cat.toLowerCase().includes(categoryName.value.toLowerCase())).map(cat => {
    return {
        label: cat,
        value: cat
    }
}));
const allFileSize = computed(() => newFiles.value.reduce((a, b) => a = a + b.file.size, 0));
const importMsg = computed(() => `Importing ${newFiles.value.length} files...`)


const enabled = computed({
    get: () => prefs?.value?.enabledPlaceholders ?? [],
    set: val => {
        if (prefs?.value?.enabledPlaceholders) {
            prefs.value.enabledPlaceholders = val;
        }
    }
});

const openDir = async () => {
    const fs = new FileSystemClient();
    const result = await fs.getFiles((file) => file.type.startsWith("image/"));
    dbg('loaded files', result);
    newFiles.value = result.files;
    categoryName.value = result.dir;

}

const openFile = async () => {
    const fs = new services.FileSystemClient();
    const result = await fs.getFile(fs.imageTypes);
    dbg('loaded files', result);
    newFiles.value = [result];
}

const importCurrent = async () => {
    await PlaceholderService.loadLocalPlaceholders({ categoryName: categoryName.value, files: newFiles.value }, "data");
    const n = notif.create({
        title: 'Imported!',
        duration: 4000,
        closable: true
    });
    categoryName.value = '';
    newFiles.value = [];
    emitter?.emit('reload', 'placeholders');
    loadPlaceholders().then(ph => {
        placeholders.value = ph;
    });
}

const cancelImport = () => {
    categoryName.value = '';
    newFiles.value = [];
}

watch(prefs, watchForChanges(true, updatePrefs), {deep: true})

onBeforeMount(() => {
    loadPlaceholders().then(ph => {
        placeholders.value = ph;
    })
})

const loadPlaceholders = async () => {
    const holders = await PlaceholderService.getLocalPlaceholders();
    return holders;
}

</script>
