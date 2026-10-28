package com.dalely.app

import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLDecoder

data class ParsedGeoLocation(
    val latitude: Double,
    val longitude: Double,
    val label: String? = null
)

object GeoUriParser {
    private val coordRegex = Regex("""([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)""")
    private val atCoordRegex = Regex("""@([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)""")
    private val googleDataRegex = Regex("""!3d([+-]?\d{1,2}(?:\.\d+)?)(?:!4d|.*?!4d)([+-]?\d{1,3}(?:\.\d+)?)""")
    private val parenRegex = Regex("""\(([^)]+)\)""")
    private val embeddedUrlRegex = Regex("""(https?://[^\s]+|geo:[^\s]+|feen:[^\s]+|dalely:[^\s]+)""")
    private val googlePlacePathRegex = Regex("""/(?:place|search)/([^/@?]+)""")

    fun parse(raw: String?): ParsedGeoLocation? {
        if (raw.isNullOrBlank()) return null
        val trimmed = raw.trim()
        val decoded = safeDecode(trimmed)

        // 1. Embedded URL extraction
        val match = embeddedUrlRegex.find(decoded) ?: embeddedUrlRegex.find(trimmed)
        if (match != null && match.value != decoded && match.value != trimmed) {
            val nested = parse(match.value)
            val textLabel = extractTextLabel(decoded, match.value)
            if (nested != null) {
                return nested.copy(label = textLabel ?: nested.label)
            }
        }

        // 2. Parentheses label: geo:0,0?q=lat,lng(My Store)
        val parenLabel = parenRegex.find(decoded)?.groupValues?.getOrNull(1)?.let { cleanPlaceName(it) }

        // 3. geo: scheme
        if (decoded.startsWith("geo:") || trimmed.startsWith("geo:")) {
            return parseGeo(if (decoded.startsWith("geo:")) decoded else trimmed, parenLabel)
        }

        // 4. Google Maps URLs
        if (decoded.contains("maps.google.") ||
            decoded.contains("google.com/maps") ||
            decoded.contains("goo.gl/maps") ||
            decoded.contains("maps.app.goo.gl")
        ) {
            val res = parseGoogle(decoded, parenLabel)
            if (res != null) return res
        }

        // 5. Apple Maps URLs
        if (decoded.contains("maps.apple.com")) {
            val res = parseApple(decoded, parenLabel)
            if (res != null) return res
        }

        // 6. Direct coordinate pair
        coordRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                val label = parenLabel ?: extractTextLabel(decoded, null)
                return ParsedGeoLocation(lat, lng, label)
            }
        }

        return null
    }

    suspend fun parseAsync(raw: String?): ParsedGeoLocation? = withContext(Dispatchers.IO) {
        if (raw.isNullOrBlank()) return@withContext null
        val trimmed = raw.trim()

        // Try immediate synchronous parse
        val immediate = parse(trimmed)
        if (immediate != null) return@withContext immediate

        // Check if there is an embedded URL
        val match = embeddedUrlRegex.find(trimmed) ?: embeddedUrlRegex.find(safeDecode(trimmed))
        val targetUrl = match?.value ?: trimmed

        if (!targetUrl.startsWith("http://") && !targetUrl.startsWith("https://")) {
            return@withContext null
        }

        val fallbackLabel = extractTextLabel(trimmed, targetUrl)

        // Follow HTTP redirects
        val resolvedUrl = expandShortUrl(targetUrl)
        if (resolvedUrl != null && resolvedUrl != targetUrl) {
            val parsedResolved = parse(resolvedUrl)
            if (parsedResolved != null) {
                return@withContext parsedResolved.copy(label = fallbackLabel ?: parsedResolved.label)
            }
        }

        null
    }

    private fun parseGeo(uri: String, label: String?): ParsedGeoLocation? {
        val ssp = uri.removePrefix("geo:")
        val parts = ssp.split("?", limit = 2)
        val path = parts[0]
        val query = parts.getOrNull(1) ?: ""

        if (query.isNotEmpty()) {
            val qVal = try {
                Uri.parse("x://x?$query").getQueryParameter("q")
            } catch (_: Exception) { null }
            if (qVal != null) {
                coordRegex.find(qVal)?.let { m ->
                    val lat = m.groupValues[1].toDoubleOrNull()
                    val lng = m.groupValues[2].toDoubleOrNull()
                    if (lat != null && lng != null && isValid(lat, lng)) {
                        return ParsedGeoLocation(lat, lng, label)
                    }
                }
            }
        }

        coordRegex.find(path)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, label)
            }
        }

        return null
    }

    private fun parseGoogle(decoded: String, label: String?): ParsedGeoLocation? {
        var placeLabel = label
        if (placeLabel == null) {
            val m = googlePlacePathRegex.find(decoded)
            if (m != null) {
                placeLabel = cleanPlaceName(m.groupValues[1])
            }
        }

        atCoordRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, placeLabel)
            }
        }

        googleDataRegex.find(decoded)?.let { m ->
            val lat = m.groupValues[1].toDoubleOrNull()
            val lng = m.groupValues[2].toDoubleOrNull()
            if (lat != null && lng != null && isValid(lat, lng)) {
                return ParsedGeoLocation(lat, lng, placeLabel)
            }
        }

        try {
            val uri = Uri.parse(decoded)
            for (param in listOf("q", "query", "ll", "daddr", "destination")) {
                val value = uri.getQueryParameter(param) ?: continue
                coordRegex.find(value)?.let { m ->
                    val lat = m.groupValues[1].toDoubleOrNull()
                    val lng = m.groupValues[2].toDoubleOrNull()
                    if (lat != null && lng != null && isValid(lat, lng)) {
                        return ParsedGeoLocation(lat, lng, placeLabel)
                    }
                }
            }
        } catch (_: Exception) {}

        return null
    }

    private fun parseApple(decoded: String, label: String?): ParsedGeoLocation? {
        try {
            val uri = Uri.parse(decoded)
            for (param in listOf("ll", "sll", "daddr", "q")) {
                val value = uri.getQueryParameter(param) ?: continue
                coordRegex.find(value)?.let { m ->
                    val lat = m.groupValues[1].toDoubleOrNull()
                    val lng = m.groupValues[2].toDoubleOrNull()
                    if (lat != null && lng != null && isValid(lat, lng)) {
                        val qLabel = cleanPlaceName(uri.getQueryParameter("q") ?: uri.getQueryParameter("address"))
                        return ParsedGeoLocation(lat, lng, label ?: qLabel)
                    }
                }
            }
        } catch (_: Exception) {}
        return null
    }

    private fun expandShortUrl(shortUrl: String): String? {
        var currentUrl = shortUrl
        try {
            for (hop in 0 until 5) {
                if (parse(currentUrl) != null) return currentUrl
                val conn = URL(currentUrl).openConnection() as HttpURLConnection
                conn.instanceFollowRedirects = false
                conn.connectTimeout = 4000
                conn.readTimeout = 4000
                conn.setRequestProperty(
                    "User-Agent",
                    "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
                )
                conn.connect()
                val code = conn.responseCode
                if (code in 300..399) {
                    val loc = conn.getHeaderField("Location")
                    conn.disconnect()
                    if (!loc.isNullOrBlank()) {
                        val next = if (loc.startsWith("http://") || loc.startsWith("https://")) {
                            loc
                        } else {
                            URL(URL(currentUrl), loc).toString()
                        }
                        currentUrl = next
                        if (parse(currentUrl) != null) return currentUrl
                        continue
                    }
                }
                conn.disconnect()
                break
            }
        } catch (_: Exception) {}
        return currentUrl
    }

    fun cleanPlaceName(raw: String?): String? {
        if (raw.isNullOrBlank()) return null
        var text = safeDecode(raw).trim()
            .replace(Regex("""[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]"""), "")
            .replace('\u00A0', ' ')
            .replace('+', ' ')
            .replace(embeddedUrlRegex, "")
            .replace(coordRegex, "")
            .trim()

        val ignored = listOf(
            "dropped pin", "pinned location", "shared location",
            "موقع تم وضع علامة عليه", "علامة موضع", "موقع محدد", "موقع على الخريطة"
        )
        if (ignored.any { text.equals(it, ignoreCase = true) || text.startsWith("$it:") || text.startsWith("$it -") }) {
            return null
        }

        // Split by delimiters to extract just the place name
        val delimiterRegex = Regex("""[,،、，;·•|]|\s+[-—]\s+""")
        if (delimiterRegex.containsMatchIn(text)) {
            val parts = text.split(delimiterRegex)
            for (part in parts) {
                val candidate = part.trim()
                if (candidate.isNotEmpty() && !candidate.matches(Regex("""^\d+$"""))) {
                    text = candidate
                    break
                }
            }
        }

        text = text.replace(Regex("""^["'«“‘\[\(]+|["'»”’\]\)]+$"""), "").trim()
        if (text.isEmpty() || text.matches(Regex("""^[\d\s\-_.,،;:]+$"""))) {
            return null
        }
        return text
    }

    private fun extractTextLabel(text: String, excludeUrl: String?): String? {
        var cleaned = text
        if (!excludeUrl.isNullOrEmpty()) {
            cleaned = cleaned.replace(excludeUrl, "")
        }
        val lines = cleaned.split("\n")
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) continue
            if (coordRegex.matches(trimmed)) continue
            if (trimmed.startsWith("http://") || trimmed.startsWith("https://") ||
                trimmed.startsWith("geo:") || trimmed.startsWith("feen:") || trimmed.startsWith("dalely:")
            ) continue
            val candidate = cleanPlaceName(trimmed)
            if (!candidate.isNullOrEmpty()) return candidate
        }
        return null
    }

    private fun safeDecode(input: String): String {
        return try {
            URLDecoder.decode(input, "UTF-8")
        } catch (_: Exception) {
            input
        }
    }

    private fun isValid(lat: Double, lng: Double): Boolean {
        return lat in -90.0..90.0 && lng in -180.0..180.0
    }
}
