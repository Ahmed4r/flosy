import json

with open(r'c:\Users\ahmed\AndroidStudioProjects\flosy\assets\translations\ar.json', 'r', encoding='utf-8-sig') as f:
    ar = json.load(f)

ar['ai'] = {
    "title": "رؤى ذكية",
    "analyzing": "جاري تحليل معاملاتك...",
    "no_data": "لا توجد بيانات كافية",
    "no_data_desc": "أضف معاملات لمدة شهرين على الأقل للحصول على توقعات مدعومة بالذكاء الاصطناعي",
    "error": "حدث خطأ",
    "insights": "الرؤى",
    "predictions": "التوقعات",
    "predicted_total": "الإجمالي المتوقع",
    "potential_savings": "التوفير المحتمل",
    "current": "الحالي",
    "predicted": "المتوقع",
    "confidence": "الثقة",
    "increase_by": "متوقع زيادة بمقدار",
    "decrease_by": "متوقع انخفاض بمقدار",
    "warning": "تحذير",
    "tip": "نصيحة",
    "achievement": "إنجاز",
    "info": "معلومة",
    "high_growth_alert": "تنبيه نمو مرتفع",
    "high_growth_desc": "{}: نموذج الذكاء الاصطناعي اكتشف نموا بنسبة {}%. ننصح بوضع ميزانية.",
    "high_confidence": "توقعات عالية الثقة",
    "high_confidence_desc": "نموذج الذكاء الاصطناعي لديه {} توقعات بثقة +85% بناء على أنماط إنفاقك المستقرة.",
    "smart_savings": "نصيحة توفير ذكية",
    "smart_savings_desc": "الذكاء الاصطناعي يقترح: تقليل {} بنسبة 15% يمكن أن يوفر لك {}/شهر.",
    "great_control": "سيطرة ممتازة!",
    "great_control_desc": "أنت تحافظ على إنفاق مستقر في {} فئات. انضباط مالي رائع!",
    "ai_active": "التحليل الذكي نشط",
    "ai_active_desc": "يتم تحليل {} معاملة بالذكاء الاصطناعي للتنبؤ بأنماط إنفاقك.",
    "powered_by": "مدعوم بـ TensorFlow Lite"
}

with open(r'c:\Users\ahmed\AndroidStudioProjects\flosy\assets\translations\ar.json', 'w', encoding='utf-8') as f:
    json.dump(ar, f, ensure_ascii=False, indent=2)

print('ar.json done')

with open(r'c:\Users\ahmed\AndroidStudioProjects\flosy\assets\translations\en.json', 'r', encoding='utf-8-sig') as f:
    en = json.load(f)

en['ai'] = {
    "title": "AI Insights",
    "analyzing": "Analyzing your transactions...",
    "no_data": "Not Enough Data",
    "no_data_desc": "Add transactions for at least 2 months to get AI-powered predictions",
    "error": "An error occurred",
    "insights": "INSIGHTS",
    "predictions": "PREDICTIONS",
    "predicted_total": "Predicted Total",
    "potential_savings": "Potential Savings",
    "current": "Current",
    "predicted": "Predicted",
    "confidence": "confidence",
    "increase_by": "Expected to increase by",
    "decrease_by": "Expected to decrease by",
    "warning": "WARNING",
    "tip": "TIP",
    "achievement": "ACHIEVEMENT",
    "info": "INFO",
    "high_growth_alert": "High Growth Alert",
    "high_growth_desc": "{}: AI model detected {}% growth. Consider setting a budget.",
    "high_confidence": "High Confidence Predictions",
    "high_confidence_desc": "AI model has {} predictions with +85% confidence based on your stable spending patterns.",
    "smart_savings": "Smart Savings Tip",
    "smart_savings_desc": "AI suggests: Reducing {} by 15% could save you {}/month.",
    "great_control": "Excellent Control!",
    "great_control_desc": "You are maintaining stable spending in {} categories. Great financial discipline!",
    "ai_active": "AI Analysis Active",
    "ai_active_desc": "{} transactions analyzed by AI to predict your spending patterns.",
    "powered_by": "Powered by TensorFlow Lite"
}

with open(r'c:\Users\ahmed\AndroidStudioProjects\flosy\assets\translations\en.json', 'w', encoding='utf-8') as f:
    json.dump(en, f, ensure_ascii=False, indent=2)

print('en.json done')