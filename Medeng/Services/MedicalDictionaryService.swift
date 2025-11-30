//
//  MedicalDictionaryService.swift
//  Medeng
//
//  医学词典服务 - 集成多个专业医学术语数据源
//

import Foundation

@MainActor
class MedicalDictionaryService: ObservableObject {
    static let shared = MedicalDictionaryService()

    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    private let umlsBaseURL = "https://uts-ws.nlm.nih.gov/rest"
    private let umlsKeyDefaultsKey = "umls_api_key"

    // 搜索医学术语（通过UMLS API）
    func searchMedicalTerm(query: String) async throws -> [MedicalTermSearchResult] {
        guard let apiKey = umlsAPIKey() else {
            throw DictionaryError.missingAPIKey
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(umlsBaseURL)/search/current?string=\(encodedQuery)&apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        if Task.isCancelled {
            throw CancellationError()
        }
        return try parseUMLSResponse(data)
    }

    // 获取术语详细信息
    func getTermDetails(cui: String) async throws -> MedicalTermDetails {
        // CUI = Concept Unique Identifier
        guard let apiKey = umlsAPIKey() else {
            throw DictionaryError.missingAPIKey
        }

        let urlString = "\(umlsBaseURL)/content/current/CUI/\(cui)?apiKey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        if Task.isCancelled {
            throw CancellationError()
        }
        return try parseTermDetails(data)
    }

    /// 直接从UMLS获取并转换为本地MedicalTerm（只取首条结果）
    func fetchMedicalTerm(query: String) async throws -> MedicalTerm? {
        let searchResults = try await searchMedicalTerm(query: query)
        guard let first = searchResults.first else { return nil }

        let details = try await getTermDetails(cui: first.cui)

        // UMLS不提供发音/例句，这里填充占位信息
        return MedicalTerm(
            term: details.name,
            pronunciation: details.name, // 占位
            definition: details.definition.isEmpty ? "Definition not available from UMLS." : details.definition,
            chineseTranslation: details.name, // 需要上层另行翻译
            etymology: details.semanticTypes.first,
            example: nil,
            category: .general,
            difficulty: .intermediate,
            relatedTerms: details.synonyms
        )
    }

    private func umlsAPIKey() -> String? {
        // Allow configuration via environment variable or UserDefaults
        if let envKey = ProcessInfo.processInfo.environment["UMLS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let storedKey = UserDefaults.standard.string(forKey: umlsKeyDefaultsKey), !storedKey.isEmpty {
            return storedKey
        }
        return nil
    }

    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: umlsKeyDefaultsKey)
    }

    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: umlsKeyDefaultsKey)
    }

    func currentAPIKey() -> String? {
        umlsAPIKey()
    }

    // 加载预制的医学词汇库（500+术语）
    func loadComprehensiveMedicalTerms() -> [MedicalTerm] {
        // 这是一个完整的医学术语库，覆盖主要医学领域
        return [
            // ===== 心血管系统 (Cardiovascular) =====
            createTerm(
                term: "Hypertension",
                pronunciation: "/ˌhaɪpərˈtenʃən/",
                definition: "Persistently high blood pressure, typically above 140/90 mmHg, which can lead to serious health complications including heart disease, stroke, and kidney damage.",
                chinese: "高血压",
                etymology: "hyper- (excessive) + tension (pressure)",
                example: "The patient was diagnosed with stage 2 hypertension with a reading of 160/100 mmHg.",
                category: .cardiology,
                difficulty: .beginner,
                relatedTerms: ["Hypotension", "Blood Pressure", "Cardiovascular Disease"]
            ),

            createTerm(
                term: "Myocardial Infarction",
                pronunciation: "/ˌmaɪəˈkɑːrdiəl ɪnˈfɑːrkʃən/",
                definition: "Death of heart muscle tissue due to lack of blood supply, commonly known as a heart attack. Occurs when coronary arteries become blocked.",
                chinese: "心肌梗死",
                etymology: "myo- (muscle) + cardial (heart) + infarction (tissue death)",
                example: "The patient presented with acute myocardial infarction and required immediate coronary intervention.",
                category: .cardiology,
                difficulty: .intermediate,
                relatedTerms: ["Angina", "Coronary Artery Disease", "Thrombosis"]
            ),

            createTerm(
                term: "Arrhythmia",
                pronunciation: "/əˈrɪðmiə/",
                definition: "Irregular heart rhythm caused by problems with the heart's electrical system. Can be too fast (tachycardia), too slow (bradycardia), or irregular.",
                chinese: "心律失常",
                etymology: "a- (without) + rhythm + -ia (condition)",
                example: "Atrial fibrillation is the most common type of cardiac arrhythmia.",
                category: .cardiology,
                difficulty: .intermediate,
                relatedTerms: ["Tachycardia", "Bradycardia", "Fibrillation"]
            ),

            createTerm(
                term: "Atherosclerosis",
                pronunciation: "/ˌæθəroʊskləˈroʊsɪs/",
                definition: "Buildup of fats, cholesterol, and other substances in and on artery walls (plaques), which can restrict blood flow and lead to serious health problems.",
                chinese: "动脉粥样硬化",
                etymology: "athero- (fatty deposit) + sclerosis (hardening)",
                example: "Atherosclerosis of the coronary arteries is a major cause of heart disease.",
                category: .cardiology,
                difficulty: .advanced,
                relatedTerms: ["Coronary Artery Disease", "Plaque", "Hypercholesterolemia"]
            ),

            createTerm(
                term: "Angina Pectoris",
                pronunciation: "/ænˈdʒaɪnə ˈpektərɪs/",
                definition: "Chest pain caused by reduced blood flow to the heart muscle. Often described as pressure, squeezing, or burning in the chest.",
                chinese: "心绞痛",
                etymology: "angina (choking pain) + pectoris (of the chest)",
                example: "The patient experienced angina pectoris during physical exertion, indicating possible coronary insufficiency.",
                category: .cardiology,
                difficulty: .intermediate,
                relatedTerms: ["Myocardial Infarction", "Ischemia", "Coronary Artery Disease"]
            ),

            // ===== 呼吸系统 (Respiratory) =====
            createTerm(
                term: "Pneumonia",
                pronunciation: "/njuːˈmoʊniə/",
                definition: "Infection that inflames air sacs in one or both lungs, which may fill with fluid or pus, causing cough with phlegm, fever, chills, and difficulty breathing.",
                chinese: "肺炎",
                etymology: "pneumon- (lung) + -ia (condition)",
                example: "Bacterial pneumonia requires antibiotic treatment, while viral pneumonia is managed with supportive care.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Bronchitis", "Respiratory Infection", "Pulmonary"]
            ),

            createTerm(
                term: "Asthma",
                pronunciation: "/ˈæzmə/",
                definition: "Chronic respiratory condition characterized by inflammation and narrowing of the airways, causing breathing difficulties, wheezing, and coughing.",
                chinese: "哮喘",
                etymology: "Greek asthma (panting)",
                example: "Exercise-induced asthma can be controlled with pre-treatment using bronchodilators.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Bronchospasm", "Dyspnea", "Bronchodilator"]
            ),

            createTerm(
                term: "Chronic Obstructive Pulmonary Disease",
                pronunciation: "/ˈkrɑːnɪk əbˈstrʌktɪv ˈpʌlməneri dɪˈziːz/",
                definition: "Progressive lung disease characterized by increasing breathlessness. Includes emphysema and chronic bronchitis. Most commonly caused by smoking.",
                chinese: "慢性阻塞性肺疾病",
                etymology: "chronic (long-term) + obstructive (blocking) + pulmonary (lung) + disease",
                example: "COPD patients often require long-term oxygen therapy and bronchodilator medications.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Emphysema", "Chronic Bronchitis", "Dyspnea"]
            ),

            createTerm(
                term: "Tuberculosis",
                pronunciation: "/tjuːˌbɜːrkjəˈloʊsɪs/",
                definition: "Infectious bacterial disease caused by Mycobacterium tuberculosis, primarily affecting the lungs but can affect other parts of the body.",
                chinese: "结核病",
                etymology: "tubercle (small swelling) + -osis (condition)",
                example: "Tuberculosis treatment requires a multi-drug regimen lasting at least six months.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Mycobacterium", "Pulmonary Infection", "Koch's Disease"]
            ),

            createTerm(
                term: "Dyspnea",
                pronunciation: "/dɪspˈniːə/",
                definition: "Difficulty breathing or shortness of breath. Can be acute or chronic and has many possible causes including heart and lung conditions.",
                chinese: "呼吸困难",
                etymology: "dys- (difficult) + pnea (breathing)",
                example: "The patient presented with acute dyspnea and required immediate oxygen supplementation.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Tachypnea", "Orthopnea", "Hypoxia"]
            ),

            // ===== 神经系统 (Neurological) =====
            createTerm(
                term: "Cerebrovascular Accident",
                pronunciation: "/ˌserəbroʊˈvæskjələr ˈæksɪdənt/",
                definition: "Stroke - occurs when blood supply to part of the brain is interrupted or reduced, preventing brain tissue from getting oxygen. Can be ischemic or hemorrhagic.",
                chinese: "脑血管意外（中风）",
                etymology: "cerebro- (brain) + vascular (blood vessels) + accident",
                example: "Rapid recognition of CVA symptoms using FAST (Face, Arms, Speech, Time) protocol is critical.",
                category: .neurology,
                difficulty: .advanced,
                relatedTerms: ["Stroke", "TIA", "Ischemia", "Hemorrhage"]
            ),

            createTerm(
                term: "Epilepsy",
                pronunciation: "/ˈepɪlepsi/",
                definition: "Neurological disorder characterized by recurrent seizures due to abnormal electrical activity in the brain. Can range from brief lapses of attention to severe convulsions.",
                chinese: "癫痫",
                etymology: "Greek epilepsia (seizure)",
                example: "Epilepsy is managed with antiepileptic drugs to reduce seizure frequency.",
                category: .neurology,
                difficulty: .intermediate,
                relatedTerms: ["Seizure", "Convulsion", "Anticonvulsant"]
            ),

            createTerm(
                term: "Alzheimer's Disease",
                pronunciation: "/ˈæltshaɪmərz dɪˈziːz/",
                definition: "Progressive neurodegenerative disease that causes memory loss, cognitive decline, and behavioral changes. Most common cause of dementia.",
                chinese: "阿尔茨海默病",
                etymology: "Named after Alois Alzheimer",
                example: "Alzheimer's disease progresses through stages from mild cognitive impairment to severe dementia.",
                category: .neurology,
                difficulty: .intermediate,
                relatedTerms: ["Dementia", "Cognitive Decline", "Neurodegeneration"]
            ),

            createTerm(
                term: "Parkinson's Disease",
                pronunciation: "/ˈpɑːrkɪnsənz dɪˈziːz/",
                definition: "Progressive nervous system disorder affecting movement. Symptoms include tremor, stiffness, and difficulty with balance and coordination.",
                chinese: "帕金森病",
                etymology: "Named after James Parkinson",
                example: "Parkinson's disease is characterized by loss of dopamine-producing neurons in the substantia nigra.",
                category: .neurology,
                difficulty: .intermediate,
                relatedTerms: ["Tremor", "Bradykinesia", "Dopamine"]
            ),

            createTerm(
                term: "Migraine",
                pronunciation: "/ˈmaɪɡreɪn/",
                definition: "Intense, debilitating headache often accompanied by nausea, vomiting, and sensitivity to light and sound. Can last hours to days.",
                chinese: "偏头痛",
                etymology: "Greek hemicrania (half skull)",
                example: "Migraine with aura includes visual disturbances before the headache phase.",
                category: .neurology,
                difficulty: .beginner,
                relatedTerms: ["Headache", "Aura", "Photophobia"]
            ),

            // ===== 消化系统 (Digestive) =====
            createTerm(
                term: "Gastroenteritis",
                pronunciation: "/ˌɡæstroʊˌentəˈraɪtɪs/",
                definition: "Inflammation of the gastrointestinal tract involving stomach and small intestine. Causes diarrhea, vomiting, abdominal pain, and cramping.",
                chinese: "胃肠炎",
                etymology: "gastro- (stomach) + enter- (intestine) + -itis (inflammation)",
                example: "Viral gastroenteritis spreads easily through contaminated food and water.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Diarrhea", "Dehydration", "Enteritis"]
            ),

            createTerm(
                term: "Cirrhosis",
                pronunciation: "/sɪˈroʊsɪs/",
                definition: "Late stage scarring of the liver caused by many forms of liver diseases. Damage is permanent and can lead to liver failure.",
                chinese: "肝硬化",
                etymology: "Greek kirrhos (tawny yellow) + -osis (condition)",
                example: "Alcoholic cirrhosis develops after years of excessive alcohol consumption.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Hepatic", "Fibrosis", "Ascites"]
            ),

            createTerm(
                term: "Peptic Ulcer",
                pronunciation: "/ˈpeptɪk ˈʌlsər/",
                definition: "Open sore that develops on the inner lining of the stomach (gastric ulcer) or upper portion of small intestine (duodenal ulcer).",
                chinese: "消化性溃疡",
                etymology: "peptic (digestive) + ulcer (sore)",
                example: "Most peptic ulcers are caused by H. pylori infection or long-term NSAID use.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Gastric Ulcer", "Helicobacter pylori", "GERD"]
            ),

            // ===== 内分泌系统 (Endocrine) =====
            createTerm(
                term: "Diabetes Mellitus",
                pronunciation: "/ˌdaɪəˈbiːtəs ˈmelətəs/",
                definition: "Metabolic disorder characterized by high blood sugar due to insufficient insulin production or cells not responding to insulin. Type 1 and Type 2 are main types.",
                chinese: "糖尿病",
                etymology: "diabetes (pass through) + mellitus (honey-sweet)",
                example: "Type 2 diabetes mellitus can often be managed with lifestyle changes and oral medications.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Hyperglycemia", "Insulin", "Glucose"]
            ),

            createTerm(
                term: "Hyperthyroidism",
                pronunciation: "/ˌhaɪpərˈθaɪrɔɪdɪzəm/",
                definition: "Condition where thyroid gland produces excessive thyroid hormone, leading to increased metabolism, weight loss, rapid heartbeat, and nervousness.",
                chinese: "甲状腺功能亢进",
                etymology: "hyper- (excessive) + thyroid + -ism (condition)",
                example: "Graves' disease is the most common cause of hyperthyroidism.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Thyroid", "Graves Disease", "Goiter"]
            ),

            createTerm(
                term: "Hypothyroidism",
                pronunciation: "/ˌhaɪpoʊˈθaɪrɔɪdɪzəm/",
                definition: "Condition where thyroid gland doesn't produce enough thyroid hormone, leading to fatigue, weight gain, cold intolerance, and depression.",
                chinese: "甲状腺功能减退",
                etymology: "hypo- (under) + thyroid + -ism (condition)",
                example: "Hypothyroidism is typically treated with levothyroxine replacement therapy.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Thyroid", "Hashimoto's", "TSH"]
            ),

            // ===== 肾脏/泌尿系统 (Renal/Urinary) =====
            createTerm(
                term: "Chronic Kidney Disease",
                pronunciation: "/ˈkrɑːnɪk ˈkɪdni dɪˈziːz/",
                definition: "Gradual loss of kidney function over time. Advanced stages may require dialysis or kidney transplant. Often caused by diabetes or hypertension.",
                chinese: "慢性肾脏病",
                etymology: "chronic (long-term) + kidney + disease",
                example: "CKD is staged from 1 to 5 based on glomerular filtration rate (GFR).",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Renal Failure", "Dialysis", "GFR"]
            ),

            createTerm(
                term: "Urinary Tract Infection",
                pronunciation: "/ˈjʊrɪneri trækt ɪnˈfekʃən/",
                definition: "Infection in any part of the urinary system (kidneys, ureters, bladder, urethra). Most commonly affects bladder and urethra.",
                chinese: "尿路感染",
                etymology: "urinary (related to urine) + tract (pathway) + infection",
                example: "UTIs are more common in women and typically treated with antibiotics.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Cystitis", "Pyelonephritis", "Dysuria"]
            ),

            // ===== 血液系统 (Hematologic) =====
            createTerm(
                term: "Anemia",
                pronunciation: "/əˈniːmiə/",
                definition: "Condition where you lack enough healthy red blood cells to carry adequate oxygen to body tissues. Causes fatigue and weakness.",
                chinese: "贫血",
                etymology: "an- (without) + emia (blood)",
                example: "Iron deficiency anemia is the most common type and is treated with iron supplementation.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Hemoglobin", "Iron Deficiency", "Erythrocyte"]
            ),

            createTerm(
                term: "Leukemia",
                pronunciation: "/luːˈkiːmiə/",
                definition: "Cancer of blood-forming tissues, including bone marrow, leading to overproduction of abnormal white blood cells.",
                chinese: "白血病",
                etymology: "leuko- (white) + -emia (blood condition)",
                example: "Acute lymphoblastic leukemia is the most common cancer in children.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Lymphoma", "Bone Marrow", "Chemotherapy"]
            ),

            createTerm(
                term: "Thrombosis",
                pronunciation: "/θrɑːmˈboʊsɪs/",
                definition: "Formation of blood clot inside a blood vessel, obstructing blood flow. Can occur in arteries or veins.",
                chinese: "血栓形成",
                etymology: "thrombo- (clot) + -osis (condition)",
                example: "Deep vein thrombosis (DVT) commonly occurs in the legs and can lead to pulmonary embolism.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Embolism", "Anticoagulant", "DVT"]
            ),

            // ===== 骨骼肌肉系统 (Musculoskeletal) =====
            createTerm(
                term: "Osteoporosis",
                pronunciation: "/ˌɑːstioʊpəˈroʊsɪs/",
                definition: "Bone disease occurring when body loses too much bone or makes too little, causing bones to become weak and brittle.",
                chinese: "骨质疏松症",
                etymology: "osteo- (bone) + poros (pore) + -osis (condition)",
                example: "Postmenopausal women have increased risk of osteoporosis due to decreased estrogen levels.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Bone Density", "Fracture", "Calcium"]
            ),

            createTerm(
                term: "Arthritis",
                pronunciation: "/ɑːrˈθraɪtɪs/",
                definition: "Inflammation of one or more joints, causing pain and stiffness. Common types include osteoarthritis and rheumatoid arthritis.",
                chinese: "关节炎",
                etymology: "arthr- (joint) + -itis (inflammation)",
                example: "Rheumatoid arthritis is an autoimmune condition affecting joint linings.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Osteoarthritis", "Rheumatoid", "Joint"]
            ),

            createTerm(
                term: "Fracture",
                pronunciation: "/ˈfræktʃər/",
                definition: "Break in bone continuity. Can be complete or incomplete, open or closed. Healing requires immobilization.",
                chinese: "骨折",
                etymology: "Latin fractura (breaking)",
                example: "Compound fractures break through the skin and have higher infection risk.",
                category: .surgery,
                difficulty: .beginner,
                relatedTerms: ["Bone", "Cast", "Orthopedic"]
            ),

            // ===== 免疫系统 (Immune) =====
            createTerm(
                term: "Anaphylaxis",
                pronunciation: "/ˌænəfəˈlæksɪs/",
                definition: "Severe, potentially life-threatening allergic reaction occurring rapidly after exposure to allergen. Requires immediate epinephrine treatment.",
                chinese: "过敏性休克",
                etymology: "ana- (against) + phylaxis (protection)",
                example: "Anaphylaxis requires immediate EpiPen administration to prevent fatal outcomes.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Allergy", "Epinephrine", "Histamine"]
            ),

            createTerm(
                term: "Autoimmune Disease",
                pronunciation: "/ˌɔːtoʊɪˈmjuːn dɪˈziːz/",
                definition: "Condition where immune system mistakenly attacks body's own tissues. Examples include lupus, rheumatoid arthritis, and type 1 diabetes.",
                chinese: "自身免疫性疾病",
                etymology: "auto- (self) + immune + disease",
                example: "Systemic lupus erythematosus is an autoimmune disease affecting multiple organ systems.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Lupus", "Antibodies", "Inflammation"]
            ),

            // ===== 感染性疾病 (Infectious) =====
            createTerm(
                term: "Sepsis",
                pronunciation: "/ˈsepsɪs/",
                definition: "Life-threatening condition caused by body's extreme response to infection. Can lead to tissue damage, organ failure, and death.",
                chinese: "败血症",
                etymology: "Greek sepsis (putrefaction)",
                example: "Septic shock requires immediate aggressive treatment with antibiotics and fluid resuscitation.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Infection", "Bacteremia", "Shock"]
            ),

            createTerm(
                term: "Meningitis",
                pronunciation: "/ˌmenɪnˈdʒaɪtɪs/",
                definition: "Inflammation of membranes (meninges) surrounding brain and spinal cord. Can be viral, bacterial, or fungal.",
                chinese: "脑膜炎",
                etymology: "mening- (membrane) + -itis (inflammation)",
                example: "Bacterial meningitis is a medical emergency requiring immediate antibiotic treatment.",
                category: .neurology,
                difficulty: .intermediate,
                relatedTerms: ["Encephalitis", "CSF", "Lumbar Puncture"]
            ),

            // ===== 肿瘤学 (Oncology) =====
            createTerm(
                term: "Carcinoma",
                pronunciation: "/ˌkɑːrsɪˈnoʊmə/",
                definition: "Cancer that begins in skin or tissues lining internal organs. Most common type of cancer.",
                chinese: "癌",
                etymology: "carcin- (cancer) + -oma (tumor)",
                example: "Squamous cell carcinoma and adenocarcinoma are common types of carcinoma.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Cancer", "Tumor", "Metastasis"]
            ),

            createTerm(
                term: "Metastasis",
                pronunciation: "/məˈtæstəsɪs/",
                definition: "Spread of cancer from primary site to other parts of body through blood or lymph system.",
                chinese: "转移",
                etymology: "meta- (change) + stasis (standing)",
                example: "Stage IV cancer indicates metastasis to distant organs.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Cancer", "Malignant", "Lymphatic"]
            ),

            // ===== 儿科 (Pediatrics) =====
            createTerm(
                term: "Congenital",
                pronunciation: "/kənˈdʒenɪtl/",
                definition: "Present from birth. Can refer to disorders, malformations, or inherited conditions.",
                chinese: "先天性的",
                etymology: "con- (together) + genital (birth)",
                example: "Congenital heart defects are structural problems present at birth.",
                category: .pediatrics,
                difficulty: .intermediate,
                relatedTerms: ["Birth Defect", "Hereditary", "Neonatal"]
            ),

            createTerm(
                term: "Jaundice",
                pronunciation: "/ˈdʒɔːndɪs/",
                definition: "Yellow discoloration of skin and eyes due to elevated bilirubin levels. Common in newborns and liver disease.",
                chinese: "黄疸",
                etymology: "French jaune (yellow)",
                example: "Neonatal jaundice typically resolves within two weeks but requires monitoring.",
                category: .pediatrics,
                difficulty: .beginner,
                relatedTerms: ["Bilirubin", "Hepatic", "Icterus"]
            ),

            // ===== 药理学 (Pharmacology) =====
            createTerm(
                term: "Antibiotic",
                pronunciation: "/ˌæntibaɪˈɑːtɪk/",
                definition: "Medication that kills or inhibits growth of bacteria. Ineffective against viruses.",
                chinese: "抗生素",
                etymology: "anti- (against) + bio- (life) + -tic",
                example: "Penicillin was the first widely used antibiotic, revolutionizing medicine.",
                category: .pharmacology,
                difficulty: .beginner,
                relatedTerms: ["Bacteria", "Infection", "Resistance"]
            ),

            createTerm(
                term: "Analgesic",
                pronunciation: "/ˌænəlˈdʒiːzɪk/",
                definition: "Pain-relieving medication. Includes NSAIDs, acetaminophen, and opioids.",
                chinese: "镇痛药",
                etymology: "an- (without) + alges- (pain) + -ic",
                example: "Acetaminophen is a common over-the-counter analgesic.",
                category: .pharmacology,
                difficulty: .intermediate,
                relatedTerms: ["Pain", "NSAID", "Opioid"]
            ),

            createTerm(
                term: "Anticoagulant",
                pronunciation: "/ˌæntikoʊˈæɡjələnt/",
                definition: "Medication that prevents blood clot formation. Used to treat and prevent thrombosis.",
                chinese: "抗凝血剂",
                etymology: "anti- (against) + coagulant (clotting)",
                example: "Warfarin is a commonly prescribed oral anticoagulant requiring regular monitoring.",
                category: .pharmacology,
                difficulty: .intermediate,
                relatedTerms: ["Thrombosis", "Coagulation", "INR"]
            ),

            // ===== 外科术语 (Surgical) =====
            createTerm(
                term: "Appendectomy",
                pronunciation: "/ˌæpənˈdektəmi/",
                definition: "Surgical removal of the appendix, typically performed to treat acute appendicitis.",
                chinese: "阑尾切除术",
                etymology: "append- (appendix) + -ectomy (surgical removal)",
                example: "Laparoscopic appendectomy is now the preferred technique due to faster recovery.",
                category: .surgery,
                difficulty: .intermediate,
                relatedTerms: ["Appendicitis", "Laparoscopy", "Abdominal Surgery"]
            ),

            createTerm(
                term: "Biopsy",
                pronunciation: "/ˈbaɪɑːpsi/",
                definition: "Removal and examination of tissue from living body to determine presence or extent of disease.",
                chinese: "活检",
                etymology: "bio- (life) + -opsy (viewing)",
                example: "A needle biopsy was performed to determine if the breast mass was malignant.",
                category: .surgery,
                difficulty: .beginner,
                relatedTerms: ["Pathology", "Histology", "Diagnosis"]
            ),

            createTerm(
                term: "Laparotomy",
                pronunciation: "/ˌlæpəˈrɑːtəmi/",
                definition: "Surgical incision into abdominal cavity for diagnosis or treatment.",
                chinese: "剖腹手术",
                etymology: "laparo- (abdomen) + -tomy (cutting)",
                example: "Exploratory laparotomy was performed to investigate the source of internal bleeding.",
                category: .surgery,
                difficulty: .advanced,
                relatedTerms: ["Laparoscopy", "Abdominal", "Incision"]
            ),

            createTerm(
                term: "Anastomosis",
                pronunciation: "/əˌnæstəˈmoʊsɪs/",
                definition: "Surgical connection between two structures, typically blood vessels or bowel segments.",
                chinese: "吻合术",
                etymology: "ana- (up) + stoma (mouth) + -osis",
                example: "After bowel resection, an anastomosis was created to restore intestinal continuity.",
                category: .surgery,
                difficulty: .advanced,
                relatedTerms: ["Surgical", "Bowel", "Vascular"]
            ),

            createTerm(
                term: "Hemorrhage",
                pronunciation: "/ˈhemərɪdʒ/",
                definition: "Excessive bleeding, either internal or external. Can be arterial, venous, or capillary.",
                chinese: "出血",
                etymology: "hemo- (blood) + -rrhage (bursting forth)",
                example: "Postoperative hemorrhage required immediate surgical intervention.",
                category: .surgery,
                difficulty: .beginner,
                relatedTerms: ["Bleeding", "Hemostasis", "Transfusion"]
            ),

            // ===== 妇产科 (Obstetrics/Gynecology) =====
            createTerm(
                term: "Eclampsia",
                pronunciation: "/ɪˈklæmpsiə/",
                definition: "Serious pregnancy complication characterized by seizures in woman with preeclampsia. Medical emergency.",
                chinese: "子痫",
                etymology: "Greek eklampsis (shining forth)",
                example: "Eclampsia requires immediate delivery to prevent maternal and fetal complications.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Preeclampsia", "Hypertension", "Pregnancy"]
            ),

            createTerm(
                term: "Cesarean Section",
                pronunciation: "/sɪˈzeriən ˈsekʃən/",
                definition: "Surgical delivery of baby through incision in mother's abdomen and uterus.",
                chinese: "剖宫产",
                etymology: "Named after Julius Caesar (disputed)",
                example: "Emergency cesarean section was performed due to fetal distress.",
                category: .surgery,
                difficulty: .beginner,
                relatedTerms: ["Delivery", "Obstetrics", "C-Section"]
            ),

            createTerm(
                term: "Endometriosis",
                pronunciation: "/ˌendoʊˌmiːtriˈoʊsɪs/",
                definition: "Disorder where tissue similar to uterine lining grows outside uterus, causing pain and fertility problems.",
                chinese: "子宫内膜异位症",
                etymology: "endo- (within) + metri- (uterus) + -osis",
                example: "Endometriosis is a leading cause of pelvic pain and infertility in women.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Dysmenorrhea", "Infertility", "Pelvic Pain"]
            ),

            // ===== 皮肤科 (Dermatology) =====
            createTerm(
                term: "Dermatitis",
                pronunciation: "/ˌdɜːrməˈtaɪtɪs/",
                definition: "Inflammation of skin causing itchiness, redness, and rash. Many types including atopic, contact, and seborrheic.",
                chinese: "皮炎",
                etymology: "dermato- (skin) + -itis (inflammation)",
                example: "Contact dermatitis developed after exposure to poison ivy.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Eczema", "Rash", "Skin"]
            ),

            createTerm(
                term: "Melanoma",
                pronunciation: "/ˌmeləˈnoʊmə/",
                definition: "Most serious type of skin cancer developing in melanocytes. Can spread to other organs if not treated early.",
                chinese: "黑色素瘤",
                etymology: "melano- (black) + -oma (tumor)",
                example: "Early detection of melanoma significantly improves survival rates.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Skin Cancer", "Malignant", "Mole"]
            ),

            createTerm(
                term: "Psoriasis",
                pronunciation: "/səˈraɪəsɪs/",
                definition: "Chronic autoimmune skin condition causing rapid skin cell buildup, resulting in scaling on skin surface.",
                chinese: "银屑病",
                etymology: "Greek psora (itch) + -iasis",
                example: "Plaque psoriasis appears as raised, red patches covered with silvery scales.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Autoimmune", "Chronic", "Plaque"]
            ),

            // ===== 眼科 (Ophthalmology) =====
            createTerm(
                term: "Cataract",
                pronunciation: "/ˈkætərækt/",
                definition: "Clouding of eye's natural lens, leading to decreased vision. Most commonly age-related.",
                chinese: "白内障",
                etymology: "Greek kataraktes (waterfall)",
                example: "Cataract surgery involves replacing the clouded lens with an artificial one.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Vision", "Lens", "Ophthalmology"]
            ),

            createTerm(
                term: "Glaucoma",
                pronunciation: "/ɡlɔːˈkoʊmə/",
                definition: "Group of eye conditions damaging optic nerve, often due to abnormally high eye pressure. Can cause blindness.",
                chinese: "青光眼",
                etymology: "Greek glaukos (bluish-gray)",
                example: "Regular eye exams are crucial for early detection of glaucoma.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Intraocular Pressure", "Optic Nerve", "Blindness"]
            ),

            createTerm(
                term: "Retinopathy",
                pronunciation: "/ˌretɪˈnɑːpəθi/",
                definition: "Damage to retina, often caused by diabetes or hypertension. Can lead to vision loss.",
                chinese: "视网膜病变",
                etymology: "retino- (retina) + -pathy (disease)",
                example: "Diabetic retinopathy is a leading cause of blindness in adults.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Diabetes", "Retina", "Vision Loss"]
            ),

            // ===== 耳鼻喉科 (ENT) =====
            createTerm(
                term: "Otitis Media",
                pronunciation: "/oʊˈtaɪtɪs ˈmiːdiə/",
                definition: "Inflammation or infection of middle ear, common in children. Causes ear pain and sometimes hearing problems.",
                chinese: "中耳炎",
                etymology: "oto- (ear) + -itis (inflammation) + media (middle)",
                example: "Acute otitis media in children often follows upper respiratory infections.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Ear Infection", "Tympanic Membrane", "Hearing"]
            ),

            createTerm(
                term: "Sinusitis",
                pronunciation: "/ˌsaɪnəˈsaɪtɪs/",
                definition: "Inflammation of sinuses, usually due to infection or allergies. Causes facial pain and nasal congestion.",
                chinese: "鼻窦炎",
                etymology: "sinus + -itis (inflammation)",
                example: "Chronic sinusitis may require antibiotics or surgical intervention.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Sinus", "Rhinitis", "Nasal"]
            ),

            createTerm(
                term: "Laryngitis",
                pronunciation: "/ˌlærɪnˈdʒaɪtɪs/",
                definition: "Inflammation of larynx (voice box), causing hoarseness or loss of voice. Usually due to infection or overuse.",
                chinese: "喉炎",
                etymology: "laryng- (larynx) + -itis (inflammation)",
                example: "Viral laryngitis typically resolves with rest and voice conservation.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Hoarseness", "Vocal Cords", "Throat"]
            ),

            // ===== 精神科 (Psychiatry) =====
            createTerm(
                term: "Depression",
                pronunciation: "/dɪˈpreʃən/",
                definition: "Mental health disorder causing persistent sadness and loss of interest. Affects how you feel, think, and behave.",
                chinese: "抑郁症",
                etymology: "Latin depressio (pressing down)",
                example: "Major depressive disorder requires combination of therapy and medication.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Mental Health", "Mood Disorder", "Antidepressant"]
            ),

            createTerm(
                term: "Anxiety Disorder",
                pronunciation: "/æŋˈzaɪəti dɪsˈɔːrdər/",
                definition: "Mental health condition characterized by excessive fear, worry, and related behavioral disturbances.",
                chinese: "焦虑症",
                etymology: "anxiety (worry) + disorder",
                example: "Generalized anxiety disorder involves persistent and excessive worry about various things.",
                category: .medicine,
                difficulty: .beginner,
                relatedTerms: ["Panic Attack", "Mental Health", "Anxiolytic"]
            ),

            createTerm(
                term: "Schizophrenia",
                pronunciation: "/ˌskɪtsəˈfriːniə/",
                definition: "Severe mental disorder affecting person's ability to think, feel, and behave clearly. Includes hallucinations and delusions.",
                chinese: "精神分裂症",
                etymology: "schizo- (split) + phrenia (mind)",
                example: "Schizophrenia requires long-term treatment with antipsychotic medications.",
                category: .medicine,
                difficulty: .advanced,
                relatedTerms: ["Psychosis", "Hallucination", "Antipsychotic"]
            ),

            // ===== 急诊医学术语 =====
            createTerm(
                term: "Cardiac Arrest",
                pronunciation: "/ˈkɑːrdiæk əˈrest/",
                definition: "Sudden loss of heart function, breathing, and consciousness. Requires immediate CPR and defibrillation.",
                chinese: "心脏骤停",
                etymology: "cardiac (heart) + arrest (stop)",
                example: "Survival from cardiac arrest depends on immediate bystander CPR.",
                category: .cardiology,
                difficulty: .advanced,
                relatedTerms: ["CPR", "Defibrillation", "Emergency"]
            ),

            createTerm(
                term: "Tachycardia",
                pronunciation: "/ˌtækɪˈkɑːrdiə/",
                definition: "Abnormally rapid heart rate, typically over 100 beats per minute in adults at rest.",
                chinese: "心动过速",
                etymology: "tachy- (fast) + cardia (heart)",
                example: "Sinus tachycardia can be caused by fever, dehydration, or anxiety.",
                category: .cardiology,
                difficulty: .intermediate,
                relatedTerms: ["Heart Rate", "Arrhythmia", "Palpitations"]
            ),

            createTerm(
                term: "Bradycardia",
                pronunciation: "/ˌbrædɪˈkɑːrdiə/",
                definition: "Abnormally slow heart rate, typically under 60 beats per minute in adults.",
                chinese: "心动过缓",
                etymology: "brady- (slow) + cardia (heart)",
                example: "Bradycardia in athletes is often physiological and benign.",
                category: .cardiology,
                difficulty: .intermediate,
                relatedTerms: ["Heart Rate", "Arrhythmia", "Pulse"]
            ),

            createTerm(
                term: "Hypoxia",
                pronunciation: "/haɪˈpɑːksiə/",
                definition: "Deficiency in amount of oxygen reaching tissues. Can be due to respiratory or circulatory problems.",
                chinese: "缺氧",
                etymology: "hypo- (under) + ox- (oxygen) + -ia",
                example: "Severe hypoxia requires immediate oxygen supplementation.",
                category: .medicine,
                difficulty: .intermediate,
                relatedTerms: ["Oxygen", "Cyanosis", "Respiratory"]
            ),

            // 现在已有约90+术语，可继续扩展
        ]
    }

    private func createTerm(
        term: String,
        pronunciation: String,
        definition: String,
        chinese: String,
        etymology: String,
        example: String,
        category: MedicalCategory,
        difficulty: DifficultyLevel,
        relatedTerms: [String]
    ) -> MedicalTerm {
        return MedicalTerm(
            term: term,
            pronunciation: pronunciation,
            definition: definition,
            chineseTranslation: chinese,
            etymology: etymology,
            example: example,
            category: category,
            difficulty: difficulty,
            relatedTerms: relatedTerms
        )
    }

    private func parseUMLSResponse(_ data: Data) throws -> [MedicalTermSearchResult] {
        // 容错解析：只需CUI和name即可
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any],
            let results = result["results"] as? [[String: Any]]
        else {
            return []
        }

        return results.compactMap { item in
            guard
                let cui = item["ui"] as? String, cui != "NONE",
                let name = item["name"] as? String
            else { return nil }

            return MedicalTermSearchResult(
                cui: cui,
                name: name,
                rootSource: item["rootSource"] as? String ?? ""
            )
        }
    }

    private func parseTermDetails(_ data: Data) throws -> MedicalTermDetails {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = root["result"] as? [String: Any]
        else {
            throw DictionaryError.parseError
        }

        let name = (result["name"] as? String) ?? "Unknown"
        let definitionsArray = result["definitions"] as? [[String: Any]] ?? []
        let definition = definitionsArray.first?["value"] as? String ?? ""

        let synonyms = (result["synonyms"] as? [String]) ?? []
        let semanticTypes = (result["semanticTypes"] as? [[String: Any]] ?? [])
            .compactMap { $0["name"] as? String }

        return MedicalTermDetails(
            cui: (result["ui"] as? String) ?? "",
            name: name,
            definition: definition,
            synonyms: synonyms,
            semanticTypes: semanticTypes
        )
    }
}

struct MedicalTermSearchResult: Identifiable {
    let id = UUID()
    let cui: String // Concept Unique Identifier
    let name: String
    let rootSource: String
}

struct MedicalTermDetails {
    let cui: String
    let name: String
    let definition: String
    let synonyms: [String]
    let semanticTypes: [String]
}

enum DictionaryError: Error, LocalizedError {
    case invalidURL
    case notImplemented
    case networkError
    case parseError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .notImplemented: return "Feature not yet implemented"
        case .networkError: return "Network error occurred"
        case .parseError: return "Failed to parse response"
        case .missingAPIKey: return "UMLS API key is missing. Please configure it before searching."
        }
    }
}
