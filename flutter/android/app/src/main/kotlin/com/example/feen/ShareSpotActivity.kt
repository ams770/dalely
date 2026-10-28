package com.dalely.app

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Outline
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import java.util.UUID

class ShareSpotActivity : Activity() {

    private val scope = CoroutineScope(Dispatchers.Main + Job())

    private var rawSharedText: String? = null
    private var resolvedCoordinates: ParsedGeoLocation? = null
    private var isResolving: Boolean = true
    private var isSaved: Boolean = false

    private lateinit var rootBackdrop: FrameLayout
    private lateinit var sheetContainer: LinearLayout
    private lateinit var nameEditText: EditText
    private lateinit var clearButton: ImageView
    private lateinit var statusCard: LinearLayout
    private lateinit var statusIcon: ImageView
    private lateinit var statusSpinner: ProgressBar
    private lateinit var statusTextContainer: LinearLayout
    private lateinit var statusTitle: TextView
    private lateinit var statusSubtitle: TextView
    private lateinit var saveButton: LinearLayout
    private lateinit var saveButtonIcon: ImageView
    private lateinit var saveButtonText: TextView

    private val categoryViews = mutableListOf<View>()

    private val isDark: Boolean
        get() = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    private val isArabic: Boolean
        get() = Locale.getDefault().language == "ar"

    data class CategoryItem(
        val id: String,
        val nameRes: Int,
        val iconRes: Int,
        val lightColor: Int,
        val darkColor: Int
    )

    private val categories = listOf(
        CategoryItem("other", R.string.category_other, R.drawable.ic_cat_other, 0xFF3C79F3.toInt(), 0xFF38BDF8.toInt()),
        CategoryItem("restaurant", R.string.category_restaurant, R.drawable.ic_cat_restaurant, 0xFFF59E0B.toInt(), 0xFFFBBF24.toInt()),
        CategoryItem("fuel", R.string.category_fuel, R.drawable.ic_cat_fuel, 0xFFD97706.toInt(), 0xFFF59E0B.toInt()),
        CategoryItem("gym", R.string.category_gym, R.drawable.ic_cat_gym, 0xFF14B8A6.toInt(), 0xFF2DD4BF.toInt()),
        CategoryItem("mosque", R.string.category_mosque, R.drawable.ic_cat_mosque, 0xFF059669.toInt(), 0xFF10B981.toInt()),
        CategoryItem("market", R.string.category_market, R.drawable.ic_cat_market, 0xFF3C79F3.toInt(), 0xFF38BDF8.toInt()),
        CategoryItem("pharmacy", R.string.category_pharmacy, R.drawable.ic_cat_pharmacy, 0xFFEC4899.toInt(), 0xFFF472B6.toInt()),
        CategoryItem("home", R.string.category_home, R.drawable.ic_cat_home, 0xFF10B981.toInt(), 0xFF34D399.toInt()),
        CategoryItem("work", R.string.category_work, R.drawable.ic_cat_work, 0xFF8B5CF6.toInt(), 0xFFA78BFA.toInt()),
        CategoryItem("hospital", R.string.category_hospital, R.drawable.ic_cat_hospital, 0xFFEF4444.toInt(), 0xFFF87171.toInt()),
        CategoryItem("school", R.string.category_school, R.drawable.ic_cat_school, 0xFF06B6D4.toInt(), 0xFF22D3EE.toInt()),
        CategoryItem("park", R.string.category_park, R.drawable.ic_cat_park, 0xFF16A34A.toInt(), 0xFF4ADE80.toInt()),
        CategoryItem("club", R.string.category_club, R.drawable.ic_cat_club, 0xFF6366F1.toInt(), 0xFF818CF8.toInt()),
        CategoryItem("beautyCenter", R.string.category_beauty_center, R.drawable.ic_cat_beauty_center, 0xFFE11D48.toInt(), 0xFFFB7185.toInt())
    )

    private var selectedCategory: CategoryItem = categories[0] // Other is first & default

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make window transparent and edge-to-edge
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)

        extractSharedContent(intent)
        buildUi()
        resolveCoordinates()
    }

    private fun extractSharedContent(intent: Intent?) {
        if (intent == null) return
        val extraText = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        val extraSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        val clipText = if (intent.clipData != null && intent.clipData!!.itemCount > 0) {
            intent.clipData!!.getItemAt(0).coerceToText(this).toString()
        } else null
        val primaryText = if (!extraText.isNullOrBlank()) extraText else clipText

        rawSharedText = when {
            extraSubject.isNullOrBlank() -> primaryText
            primaryText.isNullOrBlank() -> extraSubject
            primaryText.contains(extraSubject) -> primaryText
            else -> "$extraSubject\n$primaryText"
        } ?: intent.data?.toString()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun buildUi() {
        val density = resources.displayMetrics.density
        fun dp(v: Float) = (v * density + 0.5f).toInt()

        // Root backdrop layout
        rootBackdrop = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.argb(120, 0, 0, 0))
            setOnClickListener {
                dismissWithAnimation()
            }
        }

        // Bottom sheet card container
        val sheetBgColor = if (isDark) Color.parseColor("#12263F") else Color.WHITE
        sheetContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val maxH = (resources.displayMetrics.heightPixels * 0.88f).toInt()
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                maxH,
                Gravity.BOTTOM
            )
            background = GradientDrawable().apply {
                setColor(sheetBgColor)
                cornerRadii = floatArrayOf(
                    dp(28f).toFloat(), dp(28f).toFloat(), // top left
                    dp(28f).toFloat(), dp(28f).toFloat(), // top right
                    0f, 0f, 0f, 0f
                )
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { /* Consume clicks inside sheet */ }
        }

        // 1. Top Grabber Pill
        val grabberContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(10f), 0, dp(8f))
        }
        val grabberPill = View(this).apply {
            val pillColor = if (isDark) Color.argb(64, 255, 255, 255) else Color.argb(50, 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(dp(40f), dp(5f))
            background = GradientDrawable().apply {
                setColor(pillColor)
                cornerRadius = dp(2.5f).toFloat()
            }
        }
        grabberContainer.addView(grabberPill)
        sheetContainer.addView(grabberContainer)

        // 2. Header: App Icon + Titles + Close Button
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(20f), dp(4f), dp(20f), dp(12f))
        }

        val appIconView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(44f), dp(44f))
            try {
                setImageDrawable(packageManager.getApplicationIcon(packageName))
            } catch (_: Exception) {
                setImageResource(R.mipmap.ic_launcher)
            }
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, dp(11f).toFloat())
                }
            }
            clipToOutline = true
        }
        header.addView(appIconView)

        val titleContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(12f)
                marginEnd = dp(8f)
            }
        }
        val titleText = TextView(this).apply {
            text = getString(R.string.share_sheet_title)
            textSize = 18f
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            setTextColor(if (isDark) Color.WHITE else Color.parseColor("#12263F"))
        }
        val subtitleText = TextView(this).apply {
            text = getString(R.string.share_sheet_subtitle)
            textSize = 12f
            setTextColor(if (isDark) Color.argb(170, 255, 255, 255) else Color.parseColor("#64748B"))
        }
        titleContainer.addView(titleText)
        titleContainer.addView(subtitleText)
        header.addView(titleContainer)

        val closeBtn = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(32f), dp(32f))
            setImageResource(R.drawable.ic_sheet_close)
            setColorFilter(if (isDark) Color.argb(180, 255, 255, 255) else Color.parseColor("#64748B"))
            val btnBg = if (isDark) Color.argb(30, 255, 255, 255) else Color.argb(18, 0, 0, 0)
            background = GradientDrawable().apply {
                setColor(btnBg)
                shape = GradientDrawable.OVAL
            }
            val p = dp(8f)
            setPadding(p, p, p, p)
            setOnClickListener {
                dismissWithAnimation()
            }
        }
        header.addView(closeBtn)
        sheetContainer.addView(header)

        // Divider line
        val divider = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 1)
            setBackgroundColor(if (isDark) Color.argb(26, 255, 255, 255) else Color.argb(18, 0, 0, 0))
        }
        sheetContainer.addView(divider)

        // 3. Spot Name Input Section
        val nameSection = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20f), dp(12f), dp(20f), dp(6f))
        }
        val nameLabel = TextView(this).apply {
            text = getString(R.string.share_sheet_spot_name)
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(if (isDark) Color.argb(230, 255, 255, 255) else Color.parseColor("#12263F"))
        }
        nameSection.addView(nameLabel)

        val nameFieldBox = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48f)).apply {
                topMargin = dp(6f)
            }
            val boxBg = if (isDark) Color.parseColor("#182433") else Color.parseColor("#F3F9FF")
            val boxBorder = if (isDark) Color.argb(30, 255, 255, 255) else Color.argb(56, 60, 121, 243)
            background = GradientDrawable().apply {
                setColor(boxBg)
                cornerRadius = dp(14f).toFloat()
                setStroke(dp(1f), boxBorder)
            }
            setPadding(dp(14f), 0, dp(12f), 0)
        }

        val pencilIcon = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(18f), dp(18f)).apply {
                marginEnd = dp(10f)
            }
            setImageResource(R.drawable.ic_sheet_pencil)
            setColorFilter(Color.parseColor("#3C79F3"))
        }
        nameFieldBox.addView(pencilIcon)

        nameEditText = EditText(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
            background = null
            hint = getString(R.string.share_sheet_spot_name_hint)
            setHintTextColor(if (isDark) Color.argb(100, 255, 255, 255) else Color.argb(100, 18, 38, 63))
            setTextColor(if (isDark) Color.WHITE else Color.parseColor("#12263F"))
            textSize = 15f
            isSingleLine = true
            imeOptions = EditorInfo.IME_ACTION_DONE
            setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_DONE) {
                    hideKeyboard()
                    true
                } else false
            }
        }
        nameFieldBox.addView(nameEditText)

        clearButton = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(20f), dp(20f))
            setImageResource(R.drawable.ic_sheet_clear)
            setColorFilter(if (isDark) Color.argb(120, 255, 255, 255) else Color.argb(90, 0, 0, 0))
            visibility = View.GONE
            setOnClickListener {
                nameEditText.setText("")
            }
        }
        nameFieldBox.addView(clearButton)

        nameEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                clearButton.visibility = if (s.isNullOrEmpty()) View.GONE else View.VISIBLE
            }
            override fun afterTextChanged(s: Editable?) {}
        })

        nameSection.addView(nameFieldBox)
        sheetContainer.addView(nameSection)

        // 4. Category Section Header
        val categoryHeader = TextView(this).apply {
            text = getString(R.string.share_sheet_category)
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(if (isDark) Color.argb(230, 255, 255, 255) else Color.parseColor("#12263F"))
            setPadding(dp(20f), dp(8f), dp(20f), dp(4f))
        }
        sheetContainer.addView(categoryHeader)

        // 5. Vertical Scrollable List of 14 Categories
        val categoryScrollView = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f // Fills available vertical height!
            )
            isVerticalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_IF_CONTENT_SCROLLS
        }

        val categoryListContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20f), dp(4f), dp(20f), dp(6f))
        }

        categoryViews.clear()
        for (cat in categories) {
            val catRow = buildCategoryRow(cat, dp = { dp(it) })
            categoryViews.add(catRow)
            categoryListContainer.addView(catRow)
        }
        categoryScrollView.addView(categoryListContainer)
        sheetContainer.addView(categoryScrollView)

        // 6. Location Status Card
        statusCard = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val cardBg = if (isDark) Color.argb(220, 24, 36, 51) else Color.parseColor("#F8FAFC")
            val cardBorder = if (isDark) Color.argb(22, 255, 255, 255) else Color.argb(16, 0, 0, 0)
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                setMargins(dp(20f), dp(6f), dp(20f), dp(8f))
            }
            background = GradientDrawable().apply {
                setColor(cardBg)
                cornerRadius = dp(12f).toFloat()
                setStroke(dp(1f), cardBorder)
            }
            setPadding(dp(14f), dp(10f), dp(14f), dp(10f))
        }

        statusSpinner = ProgressBar(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(22f), dp(22f)).apply {
                marginEnd = dp(10f)
            }
            isIndeterminate = true
            indeterminateTintList = ColorStateList.valueOf(Color.parseColor("#3C79F3"))
        }
        statusCard.addView(statusSpinner)

        statusIcon = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(20f), dp(20f)).apply {
                marginEnd = dp(10f)
            }
            visibility = View.GONE
        }
        statusCard.addView(statusIcon)

        statusTextContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        }
        statusTitle = TextView(this).apply {
            text = getString(R.string.share_sheet_resolving)
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#3C79F3"))
        }
        statusSubtitle = TextView(this).apply {
            textSize = 12f
            typeface = Typeface.MONOSPACE
            setTextColor(if (isDark) Color.argb(170, 255, 255, 255) else Color.parseColor("#64748B"))
            visibility = View.GONE
        }
        statusTextContainer.addView(statusTitle)
        statusTextContainer.addView(statusSubtitle)
        statusCard.addView(statusTextContainer)
        sheetContainer.addView(statusCard)

        // 7. Save Action Button
        saveButton = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52f)).apply {
                setMargins(dp(20f), 0, dp(20f), dp(24f))
            }
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#94A3B8")) // initially disabled color
                cornerRadius = dp(26f).toFloat()
            }
            elevation = dp(4f).toFloat()
            isEnabled = false
            setOnClickListener {
                if (!isSaved && resolvedCoordinates != null) {
                    onSaveClicked()
                }
            }
        }

        saveButtonIcon = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(18f), dp(18f)).apply {
                marginEnd = dp(8f)
            }
            setImageResource(R.drawable.ic_sheet_check)
            setColorFilter(Color.WHITE)
        }
        saveButton.addView(saveButtonIcon)

        saveButtonText = TextView(this).apply {
            text = getString(R.string.share_sheet_save_button)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
        }
        saveButton.addView(saveButtonText)
        sheetContainer.addView(saveButton)

        rootBackdrop.addView(sheetContainer)
        setContentView(rootBackdrop)

        // Animate bottom sheet entrance
        sheetContainer.post {
            val h = sheetContainer.height.toFloat()
            sheetContainer.translationY = h
            sheetContainer.animate()
                .translationY(0f)
                .setDuration(300)
                .setInterpolator(DecelerateInterpolator())
                .start()
        }
    }

    private fun buildCategoryRow(item: CategoryItem, dp: (Float) -> Int): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(48f)).apply {
                bottomMargin = dp(8f)
            }
            setPadding(dp(14f), dp(8f), dp(14f), dp(8f))
            tag = item.id
        }

        val badgeCircle = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(34f), dp(34f)).apply {
                marginEnd = dp(12f)
            }
        }
        val icon = ImageView(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(18f), dp(18f), Gravity.CENTER)
            setImageResource(item.iconRes)
        }
        badgeCircle.addView(icon)
        row.addView(badgeCircle)

        val label = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            text = getString(item.nameRes)
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
        }
        row.addView(label)

        val checkmark = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(16f), dp(16f))
            setImageResource(R.drawable.ic_sheet_check)
            setColorFilter(Color.WHITE)
            visibility = View.GONE
        }
        row.addView(checkmark)

        updateCategoryRowStyle(row, item, isSelected = item.id == selectedCategory.id, dp)

        row.setOnClickListener {
            if (selectedCategory.id != item.id) {
                row.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                selectedCategory = item
                for (v in categoryViews) {
                    val catId = v.tag as? String ?: continue
                    val catDef = categories.find { it.id == catId } ?: continue
                    updateCategoryRowStyle(v as LinearLayout, catDef, isSelected = catDef.id == selectedCategory.id, dp)
                }
            }
        }

        return row
    }

    private fun updateCategoryRowStyle(
        row: LinearLayout,
        item: CategoryItem,
        isSelected: Boolean,
        dp: (Float) -> Int
    ) {
        val color = if (isDark) item.darkColor else item.lightColor
        val badgeCircle = row.getChildAt(0) as FrameLayout
        val icon = badgeCircle.getChildAt(0) as ImageView
        val label = row.getChildAt(1) as TextView
        val checkmark = row.getChildAt(2) as ImageView

        if (isSelected) {
            // Selected: Full color background, white text and icon
            row.background = GradientDrawable().apply {
                setColor(color)
                cornerRadius = dp(14f).toFloat()
            }
            badgeCircle.background = GradientDrawable().apply {
                setColor(Color.argb(64, 255, 255, 255))
                shape = GradientDrawable.OVAL
            }
            icon.setColorFilter(Color.WHITE)
            label.setTextColor(Color.WHITE)
            label.typeface = Typeface.DEFAULT_BOLD
            checkmark.visibility = View.VISIBLE
        } else {
            // Unselected: Light neutral background, colored icon badge
            val unselectedBg = if (isDark) Color.argb(18, 255, 255, 255) else Color.parseColor("#F1F5F9")
            val unselectedBorder = if (isDark) Color.argb(20, 255, 255, 255) else Color.parseColor("#E2E8F0")
            row.background = GradientDrawable().apply {
                setColor(unselectedBg)
                cornerRadius = dp(14f).toFloat()
                setStroke(dp(0.8f), unselectedBorder)
            }
            badgeCircle.background = GradientDrawable().apply {
                setColor(Color.argb(36, Color.red(color), Color.green(color), Color.blue(color)))
                shape = GradientDrawable.OVAL
            }
            icon.setColorFilter(color)
            label.setTextColor(if (isDark) Color.WHITE else Color.parseColor("#12263F"))
            label.typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            checkmark.visibility = View.GONE
        }
    }

    private fun resolveCoordinates() {
        val direct = GeoUriParser.parse(rawSharedText)
        if (direct != null) {
            applyResolvedCoordinates(direct)
            return
        }

        scope.launch {
            val asyncParsed = GeoUriParser.parseAsync(rawSharedText)
            if (asyncParsed != null) {
                applyResolvedCoordinates(asyncParsed)
            } else {
                applyResolutionFailed()
            }
        }
    }

    private fun applyResolvedCoordinates(parsed: ParsedGeoLocation) {
        resolvedCoordinates = parsed
        isResolving = false

        if (nameEditText.text.isNullOrBlank() && !parsed.label.isNullOrBlank()) {
            nameEditText.setText(parsed.label)
        }

        statusSpinner.visibility = View.GONE
        statusIcon.visibility = View.VISIBLE
        statusIcon.setImageResource(R.drawable.ic_sheet_check)
        statusIcon.setColorFilter(Color.parseColor("#0E9F75"))

        statusTitle.text = String.format(Locale.US, "%.5f, %.5f", parsed.latitude, parsed.longitude)
        statusTitle.setTextColor(if (isDark) Color.WHITE else Color.parseColor("#12263F"))
        statusTitle.typeface = Typeface.MONOSPACE

        // Enable Save Button
        val density = resources.displayMetrics.density
        saveButton.background = GradientDrawable().apply {
            setColor(Color.parseColor("#3C79F3"))
            cornerRadius = (26f * density).toInt().toFloat()
        }
        saveButton.isEnabled = true

        // Reverse geocode to get street / city address
        reverseGeocode(parsed.latitude, parsed.longitude)
    }

    private fun applyResolutionFailed() {
        isResolving = false
        statusSpinner.visibility = View.GONE
        statusIcon.visibility = View.VISIBLE
        statusIcon.setImageResource(R.drawable.ic_sheet_warning)
        statusIcon.setColorFilter(Color.parseColor("#F59E0B"))

        statusTitle.text = getString(R.string.share_sheet_resolve_failed)
        statusTitle.setTextColor(Color.parseColor("#F59E0B"))
        statusTitle.typeface = Typeface.DEFAULT_BOLD
        statusSubtitle.visibility = View.GONE

        saveButton.isEnabled = false
    }

    private fun reverseGeocode(lat: Double, lng: Double) {
        scope.launch(Dispatchers.IO) {
            try {
                val geocoder = Geocoder(this@ShareSpotActivity, Locale.getDefault())
                val addresses = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    var result: List<Address>? = null
                    geocoder.getFromLocation(lat, lng, 1) { list ->
                        result = list
                    }
                    result
                } else {
                    @Suppress("DEPRECATION")
                    geocoder.getFromLocation(lat, lng, 1)
                }

                val address = addresses?.firstOrNull()
                if (address != null) {
                    val parts = mutableListOf<String>()
                    address.thoroughfare?.let { parts.add(it) }
                    address.locality?.let { parts.add(it) }
                    val fullAddress = if (parts.isNotEmpty()) parts.joinToString(", ") else address.featureName

                    withContext(Dispatchers.Main) {
                        if (!fullAddress.isNullOrBlank()) {
                            statusSubtitle.text = fullAddress
                            statusSubtitle.visibility = View.VISIBLE
                            if (nameEditText.text.isNullOrBlank() && !address.featureName.isNullOrBlank()) {
                                nameEditText.setText(address.featureName)
                            }
                        }
                    }
                }
            } catch (_: Exception) {}
        }
    }

    private fun onSaveClicked() {
        val coord = resolvedCoordinates ?: return
        isSaved = true

        saveButton.performHapticFeedback(HapticFeedbackConstants.CONFIRM)

        // Update save button to success state
        val density = resources.displayMetrics.density
        saveButton.background = GradientDrawable().apply {
            setColor(Color.parseColor("#0E9F75"))
            cornerRadius = (26f * density).toInt().toFloat()
        }
        saveButtonText.text = getString(R.string.share_sheet_saved_success)
        saveButtonIcon.setImageResource(R.drawable.ic_sheet_check)
        saveButton.isEnabled = false

        // Build spot model
        val enteredName = nameEditText.text?.toString()?.trim()
        val finalName = if (!enteredName.isNullOrEmpty()) enteredName else getString(selectedCategory.nameRes)
        val now = System.currentTimeMillis()
        val spotId = "spot_" + UUID.randomUUID().toString()

        val spotObj = JSONObject().apply {
            put("id", spotId)
            put("name", finalName)
            put("category", selectedCategory.id)
            put("latitude", coord.latitude)
            put("longitude", coord.longitude)
            put("savedAt", now)
            put("status", "none")
        }

        // Persist to SharedPreferences
        val prefs = getSharedPreferences(CarTrackingReceiver.PREFS_NAME, Context.MODE_PRIVATE)
        val existingStr = prefs.getString("pending_saved_spots", "[]") ?: "[]"
        val jsonArray = try {
            JSONArray(existingStr)
        } catch (_: Exception) {
            JSONArray()
        }
        jsonArray.put(spotObj)
        prefs.edit().putString("pending_saved_spots", jsonArray.toString()).apply()

        // Dispatch live event to Flutter engine if active
        NotificationActionPlugin.dispatchAction("SPOT_SAVED", now, spotObj.toString())

        // Dismiss smoothly after 350ms
        sheetContainer.postDelayed({
            dismissWithAnimation()
        }, 350)
    }

    private fun dismissWithAnimation() {
        hideKeyboard()
        val h = sheetContainer.height.toFloat()
        sheetContainer.animate()
            .translationY(h)
            .setDuration(220)
            .setInterpolator(DecelerateInterpolator())
            .setListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    finish()
                    overridePendingTransition(0, 0)
                }
            })
            .start()

        rootBackdrop.animate()
            .alpha(0f)
            .setDuration(220)
            .start()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        dismissWithAnimation()
    }

    private fun hideKeyboard() {
        try {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.hideSoftInputFromWindow(sheetContainer.windowToken, 0)
        } catch (_: Exception) {}
    }
}
