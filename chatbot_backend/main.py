from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import re
import json
from datetime import datetime
import uuid
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
import os

# Initialize NLTK (download required data)
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt')

try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('stopwords')

try:
    nltk.data.find('corpora/wordnet')
except LookupError:
    nltk.download('wordnet')

app = FastAPI(title="Sylonow Chatbot API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize NLTK components
lemmatizer = WordNetLemmatizer()
stop_words = set(stopwords.words('english'))

# Pydantic models
class ChatRequest(BaseModel):
    user_id: str
    message: str
    conversation_id: Optional[str] = None
    context: Optional[Dict[str, Any]] = None

class ChatResponse(BaseModel):
    response_id: str
    query: str
    intent: str
    confidence: float
    message: str
    type: str = "text"
    quick_replies: Optional[List[str]] = None
    action: Optional[Dict[str, Any]] = None
    requires_escalation: bool = False
    timestamp: datetime
    extracted_data: Optional[Dict[str, Any]] = None

class ConversationCreate(BaseModel):
    user_id: str
    title: str

# Intent patterns and responses
INTENT_PATTERNS = {
    'order_status': [
        r'order.*status', r'where.*order', r'track.*order', r'order.*progress',
        r'order.*update', r'order.*arrived', r'order.*delivered', r'order.*shipped',
        r'status.*order'
    ],
    'order_details': [
        r'order.*details', r'order.*information', r'view.*order', r'show.*order',
        r'order.*summary', r'order.*info', r'my.*order', r'recent.*order',
        r'my recent order', r'show.*recent.*order', r'order.*list', r'order.*history'
    ],
    'order_tracking': [
        r'track.*order', r'order.*location', r'order.*tracking', r'where.*delivery',
        r'delivery.*status', r'shipping.*status'
    ],
    'order_modification': [
        r'change.*order', r'modify.*order', r'update.*order', r'edit.*order',
        r'cancel.*order', r'refund.*order'
    ],
    'listing_search': [
        r'find.*service', r'search.*service', r'look.*service', r'browse.*service',
        r'service.*available', r'service.*list'
    ],
    'listing_details': [
        r'service.*details', r'service.*information', r'view.*service', r'service.*pricing',
        r'service.*cost', r'how.*much', r'price.*service'
    ],
    'listing_availability': [
        r'available.*when', r'service.*available', r'booking.*available', r'schedule.*service'
    ],
    'payment_status': [
        r'payment.*status', r'payment.*failed', r'payment.*successful', r'paid.*yet',
        r'payment.*pending', r'transaction.*status'
    ],
    'earnings': [
        r'earnings', r'income', r'money.*made', r'commission', r'revenue',
        r'how.*much.*earned', r'payment.*received'
    ],
    'profile': [
        r'profile', r'account', r'personal.*info', r'update.*details', r'my.*info',
        r'account.*settings', r'profile.*information'
    ],
    'support': [
        r'help', r'support', r'assistance', r'problem', r' issue', r'error',
        r'contact.*support', r'customer.*service'
    ],
    'general': [
        r'hello', r'hi', r'hey', r'how.*are.*you', r'what.*can.*you.*do',
        r'introduction', r'about.*you'
    ]
}

RESPONSE_TEMPLATES = {
    'order_status': {
        'high': "I can help you check your order status. Could you please provide your order ID or tell me which order you'd like to check?",
        'medium': "I'd be happy to help you check your order status. Please share your order ID.",
        'low': "I understand you want to check an order status. For accurate information, please provide your order ID or contact our support team."
    },
    'order_details': {
        'high': "I can show you the details of your order. Please provide your order ID so I can fetch the information for you.",
        'medium': "I'd like to help you view your order details. Could you share your order ID?",
        'low': "For order details, please provide your order ID or reach out to our support team for assistance."
    },
    'listing_details': {
        'high': "I can help you find service details and pricing. What type of service are you looking for?",
        'medium': "I'd be happy to help you explore our services. What specific service interests you?",
        'low': "For detailed service information, please specify what you're looking for or contact our support team."
    },
    'payment_status': {
        'high': "I can check your payment status for you. Could you provide the order ID or transaction details?",
        'medium': "Let me help you check your payment status. Please share the relevant order or transaction information.",
        'low': "For payment status inquiries, please provide order details or contact our support team."
    },
    'earnings': {
        'high': "I can help you check your earnings and payment history. Would you like to see your total earnings or recent payments?",
        'medium': "I'd be happy to show you your earnings information. What would you like to know?",
        'low': "For earnings and payment information, please contact our support team for detailed assistance."
    },
    'support': {
        'high': "I'm here to help! What specific issue are you facing? I can assist with common problems or connect you with our support team.",
        'medium': "I understand you need assistance. Could you describe the issue you're facing?",
        'low': "For complex support issues, our support team will be happy to help you directly."
    },
    'general': {
        'high': "Hello! I'm your AI assistant for Sylonow. I can help you with orders, services, payments, earnings, and general inquiries. How can I assist you today?",
        'medium': "Hi there! I'm here to help with your Sylonow experience. What would you like to know?",
        'low': "Hello! I'm your Sylonow assistant. How can I help you today?"
    },
    'unknown': {
        'high': "I'm not sure I understand your question completely. Could you please rephrase it or provide more details?",
        'medium': "I'd like to help, but I need a bit more information. Could you clarify your question?",
        'low': "I'm having trouble understanding your request. Our support team would be happy to assist you directly."
    }
}

QUICK_REPLIES = {
    'order_status': ['Check my recent orders', 'Track specific order', 'Order history'],
    'order_details': ['View order summary', 'Order items', 'Delivery address'],
    'listing_details': ['View all services', 'Search by category', 'Popular services'],
    'payment_status': ['Payment history', 'Pending payments', 'Refund status'],
    'earnings': ['Total earnings', 'Recent payments', 'Payment methods'],
    'support': ['Call support', 'Email us', 'FAQs'],
    'general': ['My orders', 'My services', 'Help'],
    'unknown': ['Help', 'Contact support', 'Start over']
}

def preprocess_text(text: str) -> List[str]:
    """Preprocess text for analysis"""
    # Convert to lowercase
    text = text.lower()

    # Remove special characters and numbers
    text = re.sub(r'[^a-zA-Z\s]', '', text)

    # Tokenize
    tokens = word_tokenize(text)

    # Remove stop words and lemmatize
    filtered_tokens = []
    for token in tokens:
        if token not in stop_words and len(token) > 1:
            filtered_tokens.append(lemmatizer.lemmatize(token))

    return filtered_tokens

def classify_intent(message: str) -> tuple[str, float]:
    """Classify user intent based on message content"""
    processed_tokens = preprocess_text(message)
    processed_text = ' '.join(processed_tokens)

    intent_scores = {}

    # Check each intent pattern
    for intent, patterns in INTENT_PATTERNS.items():
        max_score = 0.0
        for pattern in patterns:
            matches = re.findall(pattern, processed_text, re.IGNORECASE)
            if matches:
                # Calculate confidence based on pattern match quality
                score = min(1.0, len(matches) * 0.3 + 0.4)  # Base score + match bonus
                max_score = max(max_score, score)

        if max_score > 0:
            intent_scores[intent] = max_score

    # Return intent with highest score
    if intent_scores:
        best_intent = max(intent_scores, key=intent_scores.get)
        confidence = intent_scores[best_intent]
        return best_intent, confidence

    return 'unknown', 0.0

def extract_entities(message: str) -> Dict[str, Any]:
    """Extract entities like order IDs, dates, etc."""
    entities = {}

    # Extract order IDs (assuming format: #ABC123 or ORDER-123)
    order_patterns = [
        r'#([A-Za-z0-9]{6,})',
        r'order[-_]?([A-Za-z0-9]{3,})',
        r'([A-Za-z]{2,}\d{3,})'
    ]

    for pattern in order_patterns:
        matches = re.findall(pattern, message, re.IGNORECASE)
        if matches:
            entities['order_id'] = matches[0].upper()
            break

    # Extract amounts
    amount_pattern = r'₹?\s?(\d+(?:,\d{3})*(?:\.\d{2})?)'
    amount_matches = re.findall(amount_pattern, message)
    if amount_matches:
        entities['amount'] = amount_matches[0]

    return entities

def generate_response(intent: str, confidence: float, message: str) -> ChatResponse:
    """Generate appropriate response based on intent and confidence"""

    # Determine response quality based on confidence
    if confidence >= 0.8:
        response_quality = 'high'
        requires_escalation = False
    elif confidence >= 0.5:
        response_quality = 'medium'
        requires_escalation = False
    else:
        response_quality = 'low'
        requires_escalation = True

    # Get response template
    response_text = RESPONSE_TEMPLATES.get(intent, RESPONSE_TEMPLATES['unknown'])[response_quality]

    # Get quick replies
    quick_replies = QUICK_REPLIES.get(intent, QUICK_REPLIES['unknown'])

    # Extract entities
    extracted_data = extract_entities(message)

    return ChatResponse(
        response_id=str(uuid.uuid4()),
        query=message,
        intent=intent,
        confidence=confidence,
        message=response_text,
        type="text",
        quick_replies=quick_replies,
        requires_escalation=requires_escalation,
        timestamp=datetime.now(),
        extracted_data=extracted_data
    )

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """Main chat endpoint"""
    try:
        # Classify intent
        intent, confidence = classify_intent(request.message)

        # Generate response
        response = generate_response(intent, confidence, request.message)

        return response

    except Exception as e:
        # Return error response
        return ChatResponse(
            response_id=str(uuid.uuid4()),
            query=request.message,
            intent="unknown",
            confidence=0.0,
            message="I apologize, but I'm experiencing some technical difficulties. Please try again later or contact our support team.",
            requires_escalation=True,
            timestamp=datetime.now()
        )

@app.get("/quick-replies/{intent}")
async def get_quick_replies(intent: str):
    """Get quick reply suggestions for an intent"""
    replies = QUICK_REPLIES.get(intent, QUICK_REPLIES['unknown'])
    return replies

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/debug")
async def debug_endpoint(request: ChatRequest):
    """Debug endpoint to see how text is processed"""
    processed_tokens = preprocess_text(request.message)
    processed_text = ' '.join(processed_tokens)

    # Test each intent pattern
    intent_scores = {}
    for intent, patterns in INTENT_PATTERNS.items():
        max_score = 0.0
        for pattern in patterns:
            matches = re.findall(pattern, processed_text, re.IGNORECASE)
            if matches:
                score = min(1.0, len(matches) * 0.3 + 0.4)
                max_score = max(max_score, score)
        if max_score > 0:
            intent_scores[intent] = max_score

    best_intent = max(intent_scores, key=intent_scores.get) if intent_scores else 'unknown'
    confidence = intent_scores.get(best_intent, 0.0) if intent_scores else 0.0

    return {
        "original_message": request.message,
        "processed_tokens": processed_tokens,
        "processed_text": processed_text,
        "intent_scores": intent_scores,
        "best_intent": best_intent,
        "confidence": confidence,
        "matched_patterns": [
            {"intent": intent, "patterns": patterns}
            for intent, patterns in INTENT_PATTERNS.items()
            if intent in intent_scores
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)