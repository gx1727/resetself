package com.gx1727.resetself

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** 一条每日重复的提醒：由 Dart 侧按真空模式设置生成。 */
data class ReminderSpec(
    val id: Int,
    val hour: Int,
    val minute: Int,
    val title: String,
    val body: String,
    /** 日间打断对应的自省问题 id，用于通知点击后直达该问题；非日间提醒为空串。 */
    val promptId: String = "",
)

/** 提醒持久化，开机后据此重排闹钟。 */
object ReminderStore {
    private const val PREF_NAME = "resetself_resident"
    private const val KEY_REMINDERS = "reminders"

    fun save(context: Context, specs: List<ReminderSpec>) {
        val array = JSONArray()
        specs.forEach { spec ->
            array.put(
                JSONObject().apply {
                    put("id", spec.id)
                    put("hour", spec.hour)
                    put("minute", spec.minute)
                    put("title", spec.title)
                    put("body", spec.body)
                    put("promptId", spec.promptId)
                },
            )
        }
        prefs(context).edit().putString(KEY_REMINDERS, array.toString()).apply()
    }

    fun load(context: Context): List<ReminderSpec> {
        val raw = prefs(context).getString(KEY_REMINDERS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                ReminderSpec(
                    id = item.optInt("id", -1),
                    hour = item.optInt("hour", 0),
                    minute = item.optInt("minute", 0),
                    title = item.optString("title", "ResetSelf"),
                    body = item.optString("body", ""),
                    promptId = item.optString("promptId", ""),
                )
            }.filter { it.id > 0 }
        } catch (ignored: Exception) {
            emptyList()
        }
    }

    fun find(context: Context, id: Int): ReminderSpec? {
        return load(context).firstOrNull { it.id == id }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
}
