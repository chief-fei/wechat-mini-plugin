package com.zxy.ijplugin.wechat_miniprogram.utils

import com.intellij.json.JsonElementTypes
import com.intellij.json.JsonFileType
import com.intellij.json.psi.*
import com.intellij.openapi.project.Project
import com.intellij.psi.PsiManager
import com.intellij.psi.search.FilenameIndex

object ComponentJsonUtils {

    fun getUsingComponentItems(jsonPsiFile: JsonFile): MutableList<JsonProperty>? {
        val usingComponentsObjectValue = getUsingComponentPropertyValue(jsonPsiFile)
        return usingComponentsObjectValue?.propertyList
    }

    fun getUsingComponentPropertyValue(jsonPsiFile: JsonFile): JsonObject? {
        val root = jsonPsiFile.topLevelValue as? JsonObject ?: return null
        val usingComponentsProperty = root.findProperty("usingComponents") ?: return null
        return usingComponentsProperty.value as? JsonObject ?: return null
    }

    /**
     * 判断一个json文件是否是Component的配置文件
     * 具有{"component":"true"}
     */
    private fun isComponentConfiguration(jsonPsiFile: JsonFile): Boolean {
        val root = jsonPsiFile.topLevelValue as? JsonObject ?: return false
        val isComponentProperty = root.findProperty("component") ?: return false
        return isComponentProperty.value?.let {
            it is JsonBooleanLiteral && it.value
        } == true
    }

    fun getAllComponentConfigurationFile(project: Project): List<JsonFile> {
        val psiManager = PsiManager.getInstance(project)
        return FilenameIndex.getAllFilesByExt(project, JsonFileType.DEFAULT_EXTENSION)
                .mapNotNull {
                    psiManager.findFile(it)
                }.filterIsInstance<JsonFile>().filter {
                    isComponentConfiguration(it)
                }
    }

    /**
     * 在一个组件的json文件中注册另一个组件
     * @param componentConfigurationJsonFile 组件的json配置文件
     * @param targetFile 被注册的组件json文件
     */
    fun registerComponent(componentConfigurationJsonFile: JsonFile, targetFile: JsonFile) {
        val usingComponentsObjectValue = getUsingComponentPropertyValue(componentConfigurationJsonFile)
        usingComponentsObjectValue?.let {
            registerComponent(it, targetFile)
        }
    }

    fun registerComponent(usingComponentsObjectValue: JsonObject, targetFile: JsonFile) {
        val project = usingComponentsObjectValue.project
        val jsonElementGenerator = JsonElementGenerator(
                project
        )
        val closeBrace = usingComponentsObjectValue.node?.findChildByType(
                JsonElementTypes.R_CURLY
        )?.psi
        if (usingComponentsObjectValue.propertyList.isNotEmpty()) {
            usingComponentsObjectValue.addBefore(
                    jsonElementGenerator.createComma(), closeBrace
            )
        }
        usingComponentsObjectValue.addBefore(
                jsonElementGenerator.createProperty(
                        targetFile.virtualFile.nameWithoutExtension,
                        "\"${targetFile.virtualFile.getPathRelativeToRootRemoveExt(project) ?: ""}\""
                ),
                closeBrace
        )
    }

}