package app.tiktoklivecompanion

object ExternalSpeechTriggers {
    fun normalize(value: String?): String = buildString {
        var count = 0
        for (point in (value ?: ".").codePoints().toArray()) {
            if (point == 34 || point == 39) continue
            val special = Character.getType(point) in setOf(
                Character.CONNECTOR_PUNCTUATION.toInt(), Character.DASH_PUNCTUATION.toInt(),
                Character.START_PUNCTUATION.toInt(), Character.END_PUNCTUATION.toInt(),
                Character.OTHER_PUNCTUATION.toInt(), Character.MATH_SYMBOL.toInt(),
                Character.CURRENCY_SYMBOL.toInt(), Character.MODIFIER_SYMBOL.toInt(), Character.OTHER_SYMBOL.toInt())
            if (special) { appendCodePoint(point); if (++count == 5) break }
        }
    }
    fun matches(text: String, enabled: Boolean, characters: String = "."): Boolean {
        if (!enabled) return false
        val first = text.trimStart().codePoints().findFirst()
        return first.isPresent && normalize(characters).codePoints().anyMatch { it == first.asInt }
    }
}
