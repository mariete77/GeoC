#!/usr/bin/env python3
"""Analyze all question JSON files for quality issues."""

import json
import os
import glob

# Known English words that shouldn't appear in Spanish answers
ENGLISH_ANSWERS = {
    # Languages in English
    'English', 'Spanish', 'French', 'Portuguese', 'German', 'Italian', 'Dutch',
    'Arabic', 'Chinese', 'Japanese', 'Korean', 'Russian', 'Hindi', 'Bengali',
    'Turkish', 'Vietnamese', 'Thai', 'Polish', 'Ukrainian', 'Romanian', 'Dutch',
    'Hungarian', 'Czech', 'Greek', 'Swedish', 'Norwegian', 'Danish', 'Finnish',
    'Malay', 'Indonesian', 'Filipino', 'Swahili', 'Malagasy', 'Amharic', 'Burmese',
    'Nepali', 'Sinhala', 'Khmer', 'Lao', 'Dzongkha', 'Tigrinya', 'Somali',
    'Kinyarwanda', 'Kirundi', 'Tswana', 'Gikuyu', 'Kinyarwanda', 'Chibarwe',
    'Catalan', 'Galician', 'Basque', 'Welsh', 'Irish', 'Maltese', 'Luxembourgish',
    'Icelandic', 'Macedonian', 'Albanian', 'Bulgarian', 'Serbian', 'Croatian',
    'Bosnian', 'Slovenian', 'Slovak', 'Latvian', 'Lithuanian', 'Estonian',
    'Georgian', 'Armenian', 'Azerbaijani', 'Kazakh', 'Uzbek', 'Turkmen',
    'Kyrgyz', 'Tajik', 'Mongolian', 'Tibetan', 'Nepali', 'Dari', 'Pashto',
    'Urdu', 'Punjabi', 'Gujarati', 'Tamil', 'Telugu', 'Kannada', 'Malayalam',
    'Marathi', 'Bengali', 'Odia', 'Assamese', 'Sindhi', 'Kashmiri',
    'Persian (Farsi)', 'Hebrew', 'Kurdish', 'Berber', 'Hausa', 'Yoruba',
    'Igbo', 'Zulu', 'Xhosa', 'Afrikaans', 'Malagasy', 'Sesotho', 'Sundanese',
    'Javanese', 'Belizean Creole', 'Carolinian', 'Chamorro', 'Marshallese',
    'Palauan', 'Tongan', 'Samoan', 'Fijian', 'Bislama', 'Tok Pisin',
    'Solomon Islands Pijin', 'Tuvaluan', 'Kiribati', 'Nauruan',
}

# Country names in English (should be in Spanish in questions)
ENGLISH_COUNTRIES = {
    'Spain', 'France', 'Germany', 'Italy', 'Portugal', 'United Kingdom',
    'Netherlands', 'Belgium', 'Switzerland', 'Austria', 'Poland', 'Czech Republic',
    'Czechia', 'Greece', 'Turkey', 'Russia', 'Sweden', 'Norway', 'Denmark',
    'Finland', 'Ireland', 'Hungary', 'Romania', 'Bulgaria', 'Serbia',
    'Croatia', 'Slovakia', 'Slovenia', 'Ukraine', 'Belarus', 'Lithuania',
    'Latvia', 'Estonia', 'Iceland', 'Albania', 'North Macedonia', 'Moldova',
    'Montenegro', 'Bosnia and Herzegovina', 'Luxembourg', 'Malta', 'Cyprus',
    'Georgia', 'Armenia', 'Azerbaijan', 'Kazakhstan', 'Uzbekistan',
    'Turkmenistan', 'Kyrgyzstan', 'Tajikistan', 'Mongolia', 'China', 'Japan',
    'South Korea', 'North Korea', 'Taiwan', 'Hong Kong', 'Macau',
    'Philippines', 'Vietnam', 'Thailand', 'Myanmar', 'Cambodia', 'Laos',
    'Malaysia', 'Singapore', 'Indonesia', 'Brunei', 'East Timor', 'India',
    'Pakistan', 'Bangladesh', 'Sri Lanka', 'Nepal', 'Bhutan', 'Maldives',
    'Afghanistan', 'Iran', 'Iraq', 'Syria', 'Jordan', 'Lebanon', 'Israel',
    'Palestine', 'Saudi Arabia', 'United Arab Emirates', 'Kuwait', 'Bahrain',
    'Qatar', 'Oman', 'Yemen', 'Egypt', 'Libya', 'Tunisia', 'Algeria',
    'Morocco', 'Sudan', 'South Sudan', 'Ethiopia', 'Somalia', 'Kenya',
    'Tanzania', 'Uganda', 'Rwanda', 'Burundi', 'Djibouti', 'Eritrea',
    'Nigeria', 'Ghana', 'Ivory Coast', 'Senegal', 'Mali', 'Burkina Faso',
    'Niger', 'Chad', 'Cameroon', 'Gabon', 'Congo', 'DR Congo', 'Angola',
    'Mozambique', 'Madagascar', 'Zambia', 'Zimbabwe', 'Malawi', 'Botswana',
    'Namibia', 'South Africa', 'Lesotho', 'Eswatini', 'Mauritius',
    'Seychelles', 'Comoros', 'Cape Verde', 'Guinea', 'Sierra Leone',
    'Liberia', 'Togo', 'Benin', 'Mauritania', 'Gambia', 'Guinea-Bissau',
    'Equatorial Guinea', 'Sao Tome and Principe', 'Central African Republic',
    'United States', 'Canada', 'Mexico', 'Guatemala', 'Belize', 'Honduras',
    'El Salvador', 'Nicaragua', 'Costa Rica', 'Panama', 'Cuba', 'Jamaica',
    'Haiti', 'Dominican Republic', 'Puerto Rico', 'Trinidad and Tobago',
    'Barbados', 'Bahamas', 'Grenada', 'Saint Lucia', 'Saint Vincent',
    'Dominica', 'Antigua and Barbuda', 'Saint Kitts and Nevis', 'Suriname',
    'Guyana', 'Colombia', 'Venezuela', 'Ecuador', 'Peru', 'Bolivia',
    'Paraguay', 'Chile', 'Argentina', 'Uruguay', 'Brazil', 'Australia',
    'New Zealand', 'Papua New Guinea', 'Fiji', 'Solomon Islands', 'Vanuatu',
    'Samoa', 'Tonga', 'Kiribati', 'Tuvalu', 'Nauru', 'Palau',
    'Marshall Islands', 'Micronesia', 'Norfolk Island',
    'Turks and Caicos Islands', 'Cayman Islands', 'British Virgin Islands',
    'United States Virgin Islands', 'Svalbard and Jan Mayen',
    'Saint Pierre and Miquelon', 'Guadeloupe', 'Martinique',
    'Faroe Islands', 'American Samoa', 'Greenland', 'Bermuda',
    'Northern Mariana Islands', 'Caribbean Netherlands',
    'Saint Helena', 'Ascension', 'Tristan da Cunha',
}

def load_all_questions():
    """Load all questions from all JSON files."""
    all_questions = []
    files = glob.glob('scripts/questions*.json') + glob.glob('scripts/questions_*.json')
    # Exclude preguntas_muestra
    files = [f for f in files if 'muestra' not in f]
    
    for filepath in sorted(files):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                questions = json.load(f)
                for q in questions:
                    q['_source'] = os.path.basename(filepath)
                all_questions.extend(questions)
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
    return all_questions

def check_english_in_answers(questions):
    """Find questions with English answers."""
    issues = []
    for q in questions:
        answer = q.get('correctAnswer', '')
        # Check if answer is in English
        if answer in ENGLISH_ANSWERS:
            issues.append({
                'id': q['id'],
                'type': q.get('type'),
                'field': 'correctAnswer',
                'value': answer,
                'issue': 'ANSWER_IN_ENGLISH',
                'source': q.get('_source', ''),
                'questionText': q.get('questionText', ''),
            })
        
        # Check options for English
        for opt in q.get('options', []):
            if opt in ENGLISH_ANSWERS:
                issues.append({
                    'id': q['id'],
                    'type': q.get('type'),
                    'field': 'option',
                    'value': opt,
                    'issue': 'OPTION_IN_ENGLISH',
                    'source': q.get('_source', ''),
                    'questionText': q.get('questionText', ''),
                })
                break  # One hit per question is enough
    return issues

def check_wrong_capitals(questions):
    """Find capital questions where the answer is the country name, not the capital."""
    issues = []
    for q in questions:
        if q.get('type') != 'capital':
            continue
        answer = q.get('correctAnswer', '')
        country = q.get('extraData', {}).get('countryName', '')
        
        # If answer equals country name, it's wrong
        if answer == country and answer:
            issues.append({
                'id': q['id'],
                'type': 'capital',
                'field': 'correctAnswer',
                'value': answer,
                'issue': 'CAPITAL_EQUALS_COUNTRY',
                'source': q.get('_source', ''),
                'questionText': q.get('questionText', ''),
            })
    return issues

def check_missing_question_text(questions):
    """Find questions with missing or generic question text for type-answer questions."""
    issues = []
    for q in questions:
        # Type-answer questions (no options)
        has_options = bool(q.get('options', []))
        qtext = q.get('questionText', '').strip()
        qtype = q.get('type', '')
        
        # Check for empty question text
        if not qtext:
            issues.append({
                'id': q['id'],
                'type': qtype,
                'field': 'questionText',
                'value': '(empty)',
                'issue': 'MISSING_QUESTION_TEXT',
                'source': q.get('_source', ''),
                'questionText': '',
            })
            continue
        
        # Check for English country names in question text
        for country in ENGLISH_COUNTRIES:
            if country in qtext and qtype in ['capital', 'currency', 'language', 'border', 'region']:
                issues.append({
                    'id': q['id'],
                    'type': qtype,
                    'field': 'questionText',
                    'value': qtext,
                    'issue': 'ENGLISH_COUNTRY_IN_QUESTION',
                    'source': q.get('_source', ''),
                    'questionText': qtext,
                    'english_country': country,
                })
                break
        
        # Check for Spanglish ("currency" in Spanish question)
        if 'currency' in qtext.lower():
            issues.append({
                'id': q['id'],
                'type': qtype,
                'field': 'questionText',
                'value': qtext,
                'issue': 'SPANGLISH_QUESTION',
                'source': q.get('_source', ''),
                'questionText': qtext,
            })
    return issues

def check_duplicate_ids(questions):
    """Find duplicate question IDs."""
    seen = {}
    issues = []
    for q in questions:
        qid = q.get('id', '')
        if qid in seen:
            issues.append({
                'id': qid,
                'type': q.get('type'),
                'field': 'id',
                'value': qid,
                'issue': 'DUPLICATE_ID',
                'source': q.get('_source', ''),
                'questionText': q.get('questionText', ''),
                'first_source': seen[qid],
            })
        else:
            seen[qid] = q.get('_source', '')
    return issues

def main():
    print("=" * 60)
    print("QUESTION QUALITY ANALYSIS")
    print("=" * 60)
    
    questions = load_all_questions()
    print(f"\nTotal questions loaded: {len(questions)}")
    
    # Count by type
    types = {}
    for q in questions:
        t = q.get('type', 'unknown')
        types[t] = types.get(t, 0) + 1
    print("\nBy type:")
    for t, count in sorted(types.items()):
        print(f"  {t}: {count}")
    
    # Check issues
    print("\n" + "=" * 60)
    print("ISSUE 1: Answers in English")
    print("=" * 60)
    english_issues = check_english_in_answers(questions)
    print(f"Found: {len(english_issues)} questions")
    by_type = {}
    for issue in english_issues:
        t = issue['type']
        by_type[t] = by_type.get(t, 0) + 1
    for t, count in sorted(by_type.items()):
        print(f"  {t}: {count}")
    
    # Show samples
    print("\nSamples (first 15):")
    for issue in english_issues[:15]:
        print(f"  [{issue['id']}] {issue['type']} → answer: '{issue['value']}' ({issue['issue']})")
    
    print("\n" + "=" * 60)
    print("ISSUE 2: Capital = Country Name (wrong answer)")
    print("=" * 60)
    capital_issues = check_wrong_capitals(questions)
    print(f"Found: {len(capital_issues)} questions")
    for issue in capital_issues[:15]:
        print(f"  [{issue['id']}] Q: '{issue['questionText']}' → A: '{issue['value']}'")
    
    print("\n" + "=" * 60)
    print("ISSUE 3: Missing/Generic Question Text")
    print("=" * 60)
    text_issues = check_missing_question_text(questions)
    missing = [i for i in text_issues if i['issue'] == 'MISSING_QUESTION_TEXT']
    english_country = [i for i in text_issues if i['issue'] == 'ENGLISH_COUNTRY_IN_QUESTION']
    spanglish = [i for i in text_issues if i['issue'] == 'SPANGLISH_QUESTION']
    
    print(f"Missing questionText: {len(missing)}")
    for issue in missing[:10]:
        print(f"  [{issue['id']}] type: {issue['type']}")
    
    print(f"\nEnglish country in question: {len(english_country)}")
    by_type_ec = {}
    for issue in english_country:
        t = issue['type']
        by_type_ec[t] = by_type_ec.get(t, 0) + 1
    for t, count in sorted(by_type_ec.items()):
        print(f"  {t}: {count}")
    for issue in english_country[:10]:
        print(f"  [{issue['id']}] '{issue['questionText']}' (has '{issue['english_country']}')")
    
    print(f"\nSpanglish questions: {len(spanglish)}")
    for issue in spanglish[:10]:
        print(f"  [{issue['id']}] '{issue['questionText']}'")
    
    print("\n" + "=" * 60)
    print("ISSUE 4: Duplicate IDs")
    print("=" * 60)
    dup_issues = check_duplicate_ids(questions)
    print(f"Found: {len(dup_issues)} duplicates")
    for issue in dup_issues[:10]:
        print(f"  [{issue['id']}] in {issue['source']} (also in {issue['first_source']})")
    
    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    total_issues = len(english_issues) + len(capital_issues) + len(missing) + len(english_country) + len(spanglish)
    print(f"English answers/options: {len(english_issues)}")
    print(f"Wrong capitals (=country): {len(capital_issues)}")
    print(f"Missing questionText: {len(missing)}")
    print(f"English country in Q: {len(english_country)}")
    print(f"Spanglish questions: {len(spanglish)}")
    print(f"Duplicate IDs: {len(dup_issues)}")
    print(f"\nTOTAL ISSUES: {total_issues}")
    print(f"Clean questions: ~{len(questions) - max(len(english_issues), len(capital_issues))}")

if __name__ == '__main__':
    main()